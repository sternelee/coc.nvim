'use strict'
import { Neovim } from '@chemzqm/neovim'
import { Position, Range } from 'vscode-languageserver-types'
import FloatFactoryImpl, { FloatWinConfig } from '../model/floatFactory'
import Regions from '../model/regions'
import { Documentation, FloatConfig, FloatFactory, FloatOptions } from '../types'
import { isVim } from '../util/constants'
import { byteIndex, byteLength } from '../util/string'

export interface ScreenPosition {
  row: number
  col: number
}

const operateModes = ['char', 'line', 'block']
export type MsgTypes = 'error' | 'warning' | 'more'

export enum MessageLevel {
  More,
  Warning,
  Error
}

export async function getCursorPosition(nvim: Neovim): Promise<Position> {
  // vim can't count utf16
  let [line, content] = await nvim.eval(`[line('.')-1, strpart(getline('.'), 0, col('.') - 1)]`) as [number, string]
  return Position.create(line, content.length)
}

export async function getVisibleRanges(nvim: Neovim, bufnr: number, winid?: number): Promise<[number, number][]> {
  if (winid == null) {
    const spans = await nvim.call('coc#window#visible_ranges', [bufnr]) as [number, number][]
    if (spans.length === 0) return []
    return Regions.mergeSpans(spans)
  }
  const span = await nvim.call('coc#window#visible_range', [winid]) as [number, number] | null
  return span == null ? [] : [span]
}

export async function getLineAndPosition(nvim: Neovim): Promise<{ text: string, line: number, character: number }> {
  let [text, lnum, content] = await nvim.eval(`[getline('.'), line('.'), strpart(getline('.'), 0, col('.') - 1)]`) as [string, number, string]
  return { text, line: lnum - 1, character: content.length }
}

export function createFloatFactory(nvim: Neovim, conf: FloatWinConfig, defaults: FloatConfig): FloatFactory {
  let opts = Object.assign({}, defaults, conf)
  let factory = new FloatFactoryImpl(nvim)
  return {
    get window() {
      return factory.window
    },
    show: (docs: Documentation[], option?: FloatOptions) => {
      return factory.show(docs, option ? Object.assign({}, opts, option) : opts)
    },
    activated: () => {
      return factory.activated()
    },
    dispose: () => {
      factory.dispose()
    },
    checkRetrigger: bufnr => {
      return factory.checkRetrigger(bufnr)
    },
    close: () => {
      factory.close()
    }
  }
}

/**
 * Prompt user for confirm, a float/popup window would be used when possible,
 * use vim's |confirm()| function as callback.
 * @param title The prompt text.
 * @returns Result of confirm.
 */
export async function showPrompt(nvim: Neovim, title: string): Promise<boolean> {
  let res = await nvim.callAsync('coc#dialog#prompt_confirm', [title])
  return res == 1
}

/**
 * Move cursor to position.
 * @param position LSP position.
 */
export async function moveTo(nvim: Neovim, position: Position, redraw: boolean): Promise<void> {
  await nvim.call('coc#cursor#move_to', [position.line, position.character])
  if (redraw) nvim.command('redraw', true)
}

/**
 * Get current cursor character offset in document,
 * length of line break would always be 1.
 * @returns Character offset.
 */
export async function getOffset(nvim: Neovim): Promise<number> {
  return await nvim.call('coc#cursor#char_offset') as number
}

/**
 * Get screen position of current cursor(relative to editor),
 * both `row` and `col` are 0 based.
 * @returns Cursor screen position.
 */
export async function getCursorScreenPosition(nvim: Neovim): Promise<ScreenPosition> {
  let [row, col] = await nvim.call('coc#cursor#screen_pos') as [number, number]
  return { row, col }
}

export async function echoLines(nvim: Neovim, env: { cmdheight: number, columns: number }, lines: string[], truncate: boolean): Promise<void> {
  let cmdHeight = env.cmdheight
  if (lines.length > cmdHeight && truncate) {
    lines = lines.slice(0, cmdHeight)
  }
  let maxLen = env.columns - 12
  lines = lines.map(line => {
    line = line.replace(/\n/g, ' ')
    if (truncate) line = line.slice(0, maxLen)
    return line
  })
  if (truncate && lines.length == cmdHeight) {
    let last = lines[lines.length - 1]
    lines[cmdHeight - 1] = `${last.length >= maxLen ? last.slice(0, -4) : last} ...`
  }
  await nvim.call('coc#ui#echo_lines', [lines])
}

/**
 * Reveal message with highlight.
 */
export function echoMessages(nvim: Neovim, msg: string, messageType: MsgTypes, messageLevel: string): void {
  let hl: 'Error' | 'MoreMsg' | 'WarningMsg' = 'Error'
  let level = MessageLevel.Error
  switch (messageType) {
    case 'more':
      level = MessageLevel.More
      hl = 'MoreMsg'
      break
    case 'warning':
      level = MessageLevel.Warning
      hl = 'WarningMsg'
      break
  }
  if (level >= toMessageLevel(messageLevel)) {
    let method = isVim ? 'callTimer' : 'call'
    nvim[method]('coc#ui#echo_messages', [hl, ('[coc.nvim] ' + msg).split('\n')], true)
  }
}

export function toMessageLevel(level: string): MessageLevel {
  switch (level) {
    case 'error':
      return MessageLevel.Error
    case 'warning':
      return MessageLevel.Warning
    default:
      return MessageLevel.More
  }
}

/**
 * Mode could be 'char', 'line', 'cursor', 'v', 'V', '\x16'
 */
export async function getSelection(nvim: Neovim, mode: string): Promise<Range | null> {
  if (mode === 'currline') {
    let line = await nvim.call('line', ['.']) as number
    return Range.create(line - 1, 0, line, 0)
  }
  if (mode === 'cursor') {
    let position = await getCursorPosition(nvim)
    return Range.create(position, position)
  }
  let res = await nvim.call('coc#cursor#get_selection', [operateModes.includes(mode) ? 1 : 0])
  if (!res || res[0] == -1) return null
  return Range.create(res[0], res[1], res[2], res[3])
}

export async function selectRange(nvim: Neovim, range: Range, redraw: boolean): Promise<void> {
  let { start, end } = range
  let [line, endLine] = await nvim.eval(`[getline(${start.line + 1}),getline(${end.line + 1})]`) as [string, string]
  let col = line.length > 0 ? byteIndex(line, start.character) : 0
  let endCol: number
  let endLnum: number
  let toEnd = end.character == 0
  if (toEnd) {
    endLnum = end.line == 0 ? 0 : end.line - 1
    let pre = await nvim.call('getline', [endLnum + 1]) as string
    endCol = byteLength(pre)
  } else {
    endLnum = end.line
    endCol = endLine.length > 0 ? byteIndex(endLine, end.character) : 0
  }
  nvim.pauseNotification()
  nvim.command(`noa call cursor(${start.line + 1},${col + 1})`, true)
  nvim.command('normal! v', true)
  nvim.command(`noa call cursor(${endLnum + 1},${endCol})`, true)
  if (toEnd) nvim.command('normal! $', true)
  await nvim.resumeNotification(redraw)
}
