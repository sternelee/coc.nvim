'use strict'
import { TextDocument } from 'vscode-languageserver-textdocument'
import { Position, Range } from 'vscode-languageserver-types'
import { getRangeText } from '../util/textedit'
import { TextLine } from './textline'

export function computeLinesOffsets(lines: ReadonlyArray<string>, eol: boolean): number[] {
  const result: number[] = []
  let textOffset = 0
  for (let line of lines) {
    result.push(textOffset)
    textOffset += line.length + 1
  }
  if (eol) result.push(textOffset)
  return result
}

/**
 * Get the first different line
 */
export function firstDiffLine(oldLines: ReadonlyArray<string>, newLines: ReadonlyArray<string>): [number, string, string] | undefined {
  let m = Math.max(oldLines.length, newLines.length)
  for (let i = 0; i < m; i++) {
    let oldLine = oldLines[i]
    let newLine = newLines[i]
    if (oldLine !== newLine) {
      return [i + 1, oldLine ?? '', newLine ?? '']
    }
  }
  return undefined
}

/**
 * Text document that created with readonly lines.
 *
 * Created for save memory since we could reuse readonly lines.
 */
export class LinesTextDocument implements TextDocument {
  private _lineOffsets: number[] | undefined
  private _content: string
  constructor(
    public readonly uri: string,
    public readonly languageId: string,
    public readonly version: number,
    public lines: ReadonlyArray<string>,
    public readonly bufnr: number,
    public readonly eol: boolean
  ) {
  }

  private get content(): string {
    if (!this._content) {
      this._content = this.lines.join('\n') + (this.eol ? '\n' : '')
    }
    return this._content
  }

  public get length(): number {
    if (!this._content) {
      let n = this.lines.reduce((p, c) => {
        return p + c.length + 1
      }, 0)
      return this.eol ? n : n - 1
    }
    return this._content.length
  }

  public get end(): Position {
    let len = this.lines.length
    if (this.eol) return Position.create(len, 0)
    return Position.create(len - 1, this.lines[len - 1].length)
  }

  public get lineCount(): number {
    return this.lines.length + (this.eol ? 1 : 0)
  }

  public intersectWith(range: Range): Range {
    let start: Position = Position.create(0, 0)
    if (start.line < range.start.line) {
      start = range.start
    } else if (range.start.line === start.line) {
      start = Position.create(start.line, Math.max(start.character, range.start.character))
    }

    let end: Position = this.end
    if (range.end.line < end.line) {
      end = range.end
    } else if (range.end.line === end.line) {
      end = Position.create(end.line, Math.min(end.character, range.end.character))
    }

    return Range.create(start, end)
  }

  public getText(range?: Range): string {
    if (range) return getRangeText(this.lines, range)
    return this.content
  }

  public lineAt(lineOrPos: number | Position): TextLine {
    const line = Position.is(lineOrPos) ? lineOrPos.line : lineOrPos
    if (typeof line !== 'number' ||
      line < 0 ||
      line >= this.lineCount ||
      Math.floor(line) !== line) {
      throw new Error('Illegal value for `line`')
    }

    return new TextLine(line, this.lines[line] ?? '', line === this.lineCount - 1)
  }

  public positionAt(offset: number): Position {
    offset = Math.max(Math.min(offset, this.content.length), 0)
    let lineOffsets = this.getLineOffsets()
    let low = 0
    let high = lineOffsets.length
    if (high === 0) {
      return { line: 0, character: offset }
    }
    while (low < high) {
      let mid = Math.floor((low + high) / 2)
      if (lineOffsets[mid] > offset) {
        high = mid
      } else {
        low = mid + 1
      }
    }
    // low is the least x for which the line offset is larger than the current offset
    // or array.length if no line offset is larger than the current offset
    let line = low - 1
    return { line, character: offset - lineOffsets[line] }
  }

  public offsetAt(position: Position) {
    let lineOffsets = this.getLineOffsets()
    if (position.line >= lineOffsets.length) {
      return this.content.length
    } else if (position.line < 0) {
      return 0
    }
    let lineOffset = lineOffsets[position.line]
    let nextLineOffset = (position.line + 1 < lineOffsets.length) ? lineOffsets[position.line + 1] : this.content.length
    return Math.max(Math.min(lineOffset + position.character, nextLineOffset), lineOffset)
  }

  private getLineOffsets(): number[] {
    if (this._lineOffsets === undefined) {
      this._lineOffsets = computeLinesOffsets(this.lines, this.eol)
    }
    return this._lineOffsets
  }
}
