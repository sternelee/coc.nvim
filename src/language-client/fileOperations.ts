'use strict'
import { Minimatch, MinimatchOptions } from 'minimatch'
import type { ClientCapabilities, CreateFilesParams, DeleteFilesParams, Disposable, Event, FileOperationClientCapabilities, FileOperationOptions, FileOperationPatternOptions, FileOperationRegistrationOptions, ProtocolNotificationType, ProtocolRequestType, RegistrationType, RenameFilesParams, ServerCapabilities, WorkspaceEdit } from 'vscode-languageserver-protocol'
import { URI } from 'vscode-uri'
import { FileCreateEvent, FileDeleteEvent, FileRenameEvent, FileWillCreateEvent, FileWillDeleteEvent, FileWillRenameEvent } from '../core/files'
import { defaultValue } from '../util'
import { FileType, getFileType } from '../util/fs'
import { minimatch } from '../util/node'
import {
  CancellationToken, DidCreateFilesNotification, DidDeleteFilesNotification, DidRenameFilesNotification, FileOperationPatternKind, WillCreateFilesRequest, WillDeleteFilesRequest, WillRenameFilesRequest
} from '../util/protocol'
import workspace from '../workspace'
import { BaseFeature, DynamicFeature, ensure, FeatureClient, FeatureState, NextSignature, RegistrationData } from './features'
import * as UUID from './utils/uuid'

function access<T, K extends keyof T>(target: T, key: K): T[K] {
  return target[key]
}

function assign<T, K extends keyof T>(target: T, key: K, value: T[K]): void {
  target[key] = value
}

/**
 * File operation middleware
 * @since 3.16.0
 */
export interface FileOperationsMiddleware {
  didCreateFiles?: NextSignature<FileCreateEvent, void>
  willCreateFiles?: NextSignature<FileWillCreateEvent, Thenable<WorkspaceEdit | null | undefined>>
  didRenameFiles?: NextSignature<FileRenameEvent, void>
  willRenameFiles?: NextSignature<FileWillRenameEvent, Thenable<WorkspaceEdit | null | undefined>>
  didDeleteFiles?: NextSignature<FileDeleteEvent, void>
  willDeleteFiles?: NextSignature<FileWillDeleteEvent, Thenable<WorkspaceEdit | null | undefined>>
}

interface FileOperationsWorkspaceMiddleware {
  workspace?: FileOperationsMiddleware
}

interface EventWithFiles<I> {
  readonly files: ReadonlyArray<I>
}

abstract class FileOperationFeature<I, E extends EventWithFiles<I>>
  extends BaseFeature<FileOperationsWorkspaceMiddleware, object> implements DynamicFeature<FileOperationRegistrationOptions> {
  private _event: Event<E>
  private _registrationType: RegistrationType<FileOperationRegistrationOptions>
  private _clientCapability: keyof FileOperationClientCapabilities
  private _serverCapability: keyof FileOperationOptions
  private _listener: Disposable | undefined
  private _filters = new Map<
    string,
    Array<{
      scheme?: string
      matcher: Minimatch
      kind?: FileOperationPatternKind
    }>
  >()

  constructor(
    client: FeatureClient<FileOperationsWorkspaceMiddleware>,
    event: Event<E>,
    registrationType: RegistrationType<FileOperationRegistrationOptions>,
    clientCapability: keyof FileOperationClientCapabilities,
    serverCapability: keyof FileOperationOptions
  ) {
    super(client)
    this._event = event
    this._registrationType = registrationType
    this._clientCapability = clientCapability
    this._serverCapability = serverCapability
  }

  public getState(): FeatureState {
    return { kind: 'workspace', id: this._registrationType.method, registrations: this._filters.size > 0 }
  }

  public get registrationType(): RegistrationType<FileOperationRegistrationOptions> {
    return this._registrationType
  }

  public fillClientCapabilities(capabilities: ClientCapabilities): void {
    const value = ensure(ensure(capabilities, 'workspace')!, 'fileOperations')!
    // this happens n times but it is the same value so we tolerate this.
    assign(value, 'dynamicRegistration', true)
    assign(value, this._clientCapability, true)
  }

  public initialize(capabilities: ServerCapabilities): void {
    const options = capabilities.workspace?.fileOperations
    const capability = options !== undefined ? access(options, this._serverCapability) : undefined
    if (capability?.filters !== undefined) {
      try {
        this.register({
          id: UUID.generateUuid(),
          registerOptions: { filters: capability.filters },
        })
      } catch (e) {
        this._client.warn(
          `Ignoring invalid glob pattern for ${this._serverCapability} registration: ${e}`
        )
      }
    }
  }

  public register(data: RegistrationData<FileOperationRegistrationOptions>): void {
    if (!this._listener) {
      this._listener = this._event(this.send, this)
    }
    const minimatchFilter = data.registerOptions.filters.map(filter => {
      const matcher = new minimatch.Minimatch(
        filter.pattern.glob,
        FileOperationFeature.asMinimatchOptions(filter.pattern.options)
      )
      if (!matcher.makeRe()) {
        throw new Error(`Invalid pattern ${filter.pattern.glob}!`)
      }
      return { scheme: filter.scheme, matcher, kind: filter.pattern.matches }
    })
    this._filters.set(data.id, minimatchFilter)
  }

  public sendWithMiddleware<T>(fn: (...args: any[]) => Promise<T> | T, key: string, ...params: any[]): Promise<T> | T {
    const middleware = defaultValue(defaultValue(this._client.middleware, {}).workspace, {})
    return middleware[key] ? middleware[key](...params, fn) : fn(...params)
  }

  public abstract send(data: E): Promise<void>

  public unregister(id: string): void {
    this._filters.delete(id)
  }

  public dispose(): void {
    this._filters.clear()
    if (this._listener) {
      this._listener.dispose()
      this._listener = undefined
    }
  }

  public async filter(event: E, prop: (i: I) => URI): Promise<E> {
    // (Asynchronously) map each file onto a boolean of whether it matches
    // any of the globs.
    const fileMatches = await Promise.all(
      event.files.map(async item => {
        const uri = prop(item)
        // Use fsPath to make this consistent with file system watchers but help
        // minimatch to use '/' instead of `\\` if present.
        const path = uri.fsPath.replace(/\\/g, '/')
        for (const filters of this._filters.values()) {
          for (const filter of filters) {
            if (filter.scheme !== undefined && filter.scheme !== uri.scheme) {
              continue
            }
            if (filter.matcher.match(path)) {
              // The pattern matches. If kind is undefined then everything is ok
              if (filter.kind === undefined) {
                return true
              }
              const fileType = await getFileType(uri.fsPath)
              // If we can't determine the file type than we treat it as a match.
              // Dropping it would be another alternative.
              if (fileType === undefined) {
                this._client.error(`Failed to determine file type for ${uri.toString()}.`)
                return true
              }
              if (
                (fileType === FileType.File && filter.kind === FileOperationPatternKind.file) ||
                (fileType === FileType.Directory && filter.kind === FileOperationPatternKind.folder)
              ) {
                return true
              }
            } else if (filter.kind === FileOperationPatternKind.folder) {
              const fileType = await getFileType(uri.fsPath)
              if (fileType === FileType.Directory && filter.matcher.match(`${path}/`)) {
                return true
              }
            }
          }
        }
        return false
      })
    )

    // Filter the files to those that matched.
    const files = event.files.filter((_, index) => fileMatches[index])

    return { ...event, files }
  }

  public static asMinimatchOptions(options: FileOperationPatternOptions | undefined): MinimatchOptions | undefined {
    if (options === undefined) {
      return undefined
    }
    if (options.ignoreCase === true) {
      return { nocase: true }
    }
    return undefined
  }
}

abstract class NotificationFileOperationFeature<I, E extends { readonly files: ReadonlyArray<I> }, P> extends FileOperationFeature<I, E> {

  private _notificationType: ProtocolNotificationType<P, FileOperationRegistrationOptions>
  private _accessUri: (i: I) => URI
  private _createParams: (e: E) => P

  constructor(
    client: FeatureClient<FileOperationsWorkspaceMiddleware>,
    event: Event<E>,
    notificationType: ProtocolNotificationType<P, FileOperationRegistrationOptions>,
    clientCapability: keyof FileOperationClientCapabilities,
    serverCapability: keyof FileOperationOptions,
    accessUri: (i: I) => URI,
    createParams: (e: E) => P
  ) {
    super(client, event, notificationType, clientCapability, serverCapability)
    this._notificationType = notificationType
    this._accessUri = accessUri
    this._createParams = createParams
  }

  public async send(originalEvent: E): Promise<void> {
    // Create a copy of the event that has the files filtered to match what the
    // server wants.
    const filteredEvent = await this.filter(originalEvent, this._accessUri)
    if (filteredEvent.files.length) {
      const next = async (event: E): Promise<void> => {
        return this._client.sendNotification(
          this._notificationType,
          this._createParams(event)
        )
      }
      let promise = this.doSend(filteredEvent, next)
      if (promise) {
        await promise.catch(e => {
          this._client.error(`Sending notification ${this.registrationType.method} failed`, e)
        })
      }
    }
  }

  protected abstract doSend(event: E, next: (event: E) => void): void | Promise<void>
}

export class DidCreateFilesFeature extends NotificationFileOperationFeature<URI, FileCreateEvent, CreateFilesParams> {
  constructor(client: FeatureClient<FileOperationsWorkspaceMiddleware>) {
    super(
      client,
      workspace.onDidCreateFiles,
      DidCreateFilesNotification.type,
      'didCreate',
      'didCreate',
      (i: URI) => i,
      client.code2ProtocolConverter.asDidCreateFilesParams
    )
  }

  protected doSend(event: FileCreateEvent, next: (event: FileCreateEvent) => void): void | Promise<void> {
    return this.sendWithMiddleware(next, 'didCreateFiles', event)
  }
}

export class DidRenameFilesFeature extends NotificationFileOperationFeature<{ oldUri: URI; newUri: URI }, FileRenameEvent, RenameFilesParams> {
  constructor(client: FeatureClient<FileOperationsWorkspaceMiddleware>) {
    super(
      client,
      workspace.onDidRenameFiles,
      DidRenameFilesNotification.type,
      'didRename',
      'didRename',
      (i: { oldUri: URI; newUri: URI }) => i.oldUri,
      client.code2ProtocolConverter.asDidRenameFilesParams
    )
  }

  protected doSend(event: FileRenameEvent, next: (event: FileRenameEvent) => void): void | Promise<void> {
    return this.sendWithMiddleware(next, 'didRenameFiles', event)
  }
}

export class DidDeleteFilesFeature extends NotificationFileOperationFeature<URI, FileDeleteEvent, DeleteFilesParams> {
  constructor(client: FeatureClient<FileOperationsWorkspaceMiddleware>) {
    super(
      client,
      workspace.onDidDeleteFiles,
      DidDeleteFilesNotification.type,
      'didDelete',
      'didDelete',
      (i: URI) => i,
      client.code2ProtocolConverter.asDidDeleteFilesParams
    )
  }

  protected doSend(event: FileCreateEvent, next: (event: FileCreateEvent) => void): void | Promise<void> {
    return this.sendWithMiddleware(next, 'didDeleteFiles', event)
  }
}

interface RequestEvent<I> {
  readonly files: ReadonlyArray<I>
  waitUntil(thenable: Thenable<WorkspaceEdit | any>): void
}

abstract class RequestFileOperationFeature<I, E extends RequestEvent<I>, P> extends FileOperationFeature<I, E> {
  private _requestType: ProtocolRequestType<P, WorkspaceEdit | null, never, void, FileOperationRegistrationOptions>
  private _accessUri: (i: I) => URI
  private _createParams: (e: EventWithFiles<I>) => P

  constructor(
    client: FeatureClient<FileOperationsWorkspaceMiddleware>,
    event: Event<E>,
    requestType: ProtocolRequestType<P, WorkspaceEdit | null, never, void, FileOperationRegistrationOptions>,
    clientCapability: keyof FileOperationClientCapabilities,
    serverCapability: keyof FileOperationOptions,
    accessUri: (i: I) => URI,
    createParams: (e: EventWithFiles<I>) => P
  ) {
    super(client, event, requestType, clientCapability, serverCapability)
    this._requestType = requestType
    this._accessUri = accessUri
    this._createParams = createParams
  }

  public async send(originalEvent: E & RequestEvent<I>): Promise<void> {
    const waitUntil = this.waitUntil(originalEvent)
    originalEvent.waitUntil(waitUntil)
  }

  private async waitUntil(originalEvent: E): Promise<WorkspaceEdit | null | undefined> {
    // Create a copy of the event that has the files filtered to match what the
    // server wants.
    const filteredEvent = await this.filter(originalEvent, this._accessUri)

    if (filteredEvent.files.length) {
      const next = (event: EventWithFiles<I>): Promise<WorkspaceEdit | any> => {
        return this.sendRequest(this._requestType, this._createParams(event), CancellationToken.None)
      }
      return this.doSend(filteredEvent, next)
    } else {
      return undefined
    }
  }

  protected abstract doSend(event: E, next: (event: EventWithFiles<I>) => Thenable<WorkspaceEdit> | Thenable<any>): Thenable<WorkspaceEdit> | Thenable<any>
}

export class WillCreateFilesFeature extends RequestFileOperationFeature<URI, FileWillCreateEvent, CreateFilesParams> {
  constructor(client: FeatureClient<FileOperationsWorkspaceMiddleware>) {
    super(
      client,
      workspace.onWillCreateFiles,
      WillCreateFilesRequest.type,
      'willCreate',
      'willCreate',
      (i: URI) => i,
      client.code2ProtocolConverter.asWillCreateFilesParams
    )
  }

  protected doSend(event: FileWillCreateEvent, next: (event: FileWillCreateEvent) => Thenable<WorkspaceEdit> | Thenable<any>): Thenable<WorkspaceEdit> | Thenable<any> {
    return this.sendWithMiddleware(next, 'willCreateFiles', event)
  }
}

export class WillRenameFilesFeature extends RequestFileOperationFeature<{ oldUri: URI; newUri: URI }, FileWillRenameEvent, RenameFilesParams> {
  constructor(client: FeatureClient<FileOperationsWorkspaceMiddleware>) {
    super(
      client,
      workspace.onWillRenameFiles,
      WillRenameFilesRequest.type,
      'willRename',
      'willRename',
      (i: { oldUri: URI; newUri: URI }) => i.oldUri,
      client.code2ProtocolConverter.asWillRenameFilesParams
    )
  }

  protected doSend(event: FileWillRenameEvent, next: (event: FileWillRenameEvent) => Thenable<WorkspaceEdit> | Thenable<any>): Thenable<WorkspaceEdit> | Thenable<any> {
    return this.sendWithMiddleware(next, 'willRenameFiles', event)
  }
}

export class WillDeleteFilesFeature extends RequestFileOperationFeature<URI, FileWillDeleteEvent, DeleteFilesParams> {
  constructor(client: FeatureClient<FileOperationsWorkspaceMiddleware>) {
    super(
      client,
      workspace.onWillDeleteFiles,
      WillDeleteFilesRequest.type,
      'willDelete',
      'willDelete',
      (i: URI) => i,
      client.code2ProtocolConverter.asWillDeleteFilesParams
    )
  }

  protected doSend(event: FileWillDeleteEvent, next: (event: FileWillDeleteEvent) => Thenable<WorkspaceEdit> | Thenable<any>): Thenable<WorkspaceEdit> | Thenable<any> {
    return this.sendWithMiddleware(next, 'willDeleteFiles', event)
  }
}
