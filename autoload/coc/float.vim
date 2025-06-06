scriptencoding utf-8
let s:is_vim = !has('nvim')
let s:borderchars = get(g:, 'coc_borderchars', ['─', '│', '─', '│', '┌', '┐', '┘', '└'])
let s:rounded_borderchars = s:borderchars[0:3] + ['╭', '╮', '╯', '╰']
let s:borderjoinchars = get(g:, 'coc_border_joinchars', ['┬', '┤', '┴', '├'])
let s:pad_bufnr = -1

" Check visible float/popup exists.
function! coc#float#has_float(...) abort
  return len(coc#float#get_float_win_list(get(a:, 1, 0))) > 0
endfunction

function! coc#float#close_all(...) abort
  let winids = coc#float#get_float_win_list(get(a:, 1, 0))
  for id in winids
    try
      call coc#float#close(id)
    catch /E5555:/
      " ignore
    endtry
  endfor
  return ''
endfunction

function! coc#float#jump() abort
  if !s:is_vim
    let winids = coc#float#get_float_win_list()
    if !empty(winids)
      call win_gotoid(winids[0])
    endif
  endif
endfunction

function! coc#float#valid(winid) abort
  if a:winid <= 0
    return 0
  endif
  if !s:is_vim
    if !nvim_win_is_valid(a:winid)
      return 0
    endif
    return !empty(nvim_win_get_config(a:winid)['relative'])
  endif
  try
    return !empty(popup_getpos(a:winid))
  catch /^Vim\%((\a\+)\)\=:E993/
    " not a popup window
    return 0
  endtry
endfunction

function! coc#float#get_height(winid) abort
  if !s:is_vim
    let borderwin = coc#float#get_related(a:winid, 'border')
    if borderwin
      return nvim_win_get_height(borderwin)
    endif
    return nvim_win_get_height(a:winid)
  endif
  return get(popup_getpos(a:winid), 'height', 0)
endfunction

function! coc#float#change_height(winid, delta) abort
  if s:is_vim
    let curr = get(popup_getpos(a:winid), 'core_height', v:null)
    if curr isnot v:null
      call popup_move(a:winid, {
          \ 'maxheight': max([1, curr + a:delta]),
          \ 'minheight': max([1, curr + a:delta]),
          \ })
    endif
  else
    let winids = copy(coc#window#get_var(a:winid, 'related', []))
    call filter(winids, 'index(["border","pad","scrollbar"],coc#window#get_var(v:val,"kind","")) >= 0')
    call add(winids, a:winid)
    for winid in winids
      if coc#window#get_var(winid, 'kind', '') ==# 'border'
        let bufnr = winbufnr(winid)
        if a:delta > 0
          call appendbufline(bufnr, 1, repeat(getbufline(bufnr, 2), a:delta))
        else
          call deletebufline(bufnr, 2, 2 - a:delta - 1)
        endif
      endif
      let height = nvim_win_get_height(winid)
      call nvim_win_set_height(winid, max([1, height + a:delta]))
    endfor
  endif
endfunction

" create or config float window, returns [winid, bufnr], config including:
" - relative:  could be 'editor' 'cursor'
" - row: line count relative to editor/cursor, nagetive number means abover cursor.
" - col: column count relative to editor/cursor, nagetive number means left of cursor.
" - width: content width without border and title.
" - height: content height without border and title.
" - lines: (optional) lines to insert, default to v:null.
" - title: (optional) title.
" - border: (optional) border as number list, like [1, 1, 1 ,1].
" - cursorline: (optional) enable cursorline when is 1.
" - autohide: (optional) window should be closed on CursorMoved when is 1.
" - highlight: (optional) highlight of window, default to 'CocFloating'
" - borderhighlight: (optional) should be array or string for border highlights,
"   highlight all borders with first value.
" - close: (optional) show close button when is 1.
" - highlights: (optional) highlight items.
" - buttons: (optional) array of button text for create buttons at bottom.
" - codes: (optional) list of CodeBlock.
" - winblend: (optional) winblend option for float window, neovim only.
" - shadow:  (optional) use shadow as border style, neovim only.
" - focusable:  (optional) neovim only, default to true.
" - scrollinside: (optional) neovim only, create scrollbar inside window.
" - rounded: (optional) use rounded borderchars, ignored when borderchars exists.
" - zindex: (optional) zindex of window, default 50.
" - borderchars: (optional) borderchars, should be length of 8
" - nopad: (optional) not add pad when 1
" - filter: (optional) filter property on vim9.
" - index: (optional) line index
function! coc#float#create_float_win(winid, bufnr, config) abort
  let lines = get(a:config, 'lines', v:null)
  let bufnr = a:bufnr
  try
    let bufnr = coc#float#create_buf(a:bufnr, lines, 'hide')
  catch /E523:/
    " happens when using getchar() #3921
    return []
  endtry

  " Calculate position when relative is editor
  if get(a:config, 'relative', '') ==# 'editor'
    let top = get(a:config, 'top', v:null)
    let bottom = get(a:config, 'bottom', v:null)
    let left = get(a:config, 'left', v:null)
    let right = get(a:config, 'right', v:null)

    if top isnot v:null || bottom isnot v:null || left isnot v:null || right isnot v:null
      let height = &lines
      let width = &columns

      " Calculate row
      let calc_row = a:config.row
      if bottom isnot v:null
        let calc_row = height - bottom - a:config.height - 2
      elseif top isnot v:null
        let calc_row = top
      endif

      " Calculate col
      let calc_col = a:config.col
      if right isnot v:null
        let calc_col = width - right - a:config.width - 3
      elseif left isnot v:null
        let calc_col = left
      endif

      " Check if window would overlap cursor position
      let pos = screenpos(0, line('.'), col('.'))
      let currow = pos.row - 1
      let curcol = pos.col - 1
      let win_top = calc_row
      let win_bottom = win_top + a:config.height + 2
      let win_left = calc_col
      let win_right = win_left + a:config.width + 3

      " If window would overlap cursor, switch to cursor relative
      if currow >= win_top && currow <= win_bottom && curcol >= win_left && curcol <= win_right
        let a:config.relative = 'cursor'
      else
        let a:config.row = calc_row
        let a:config.col = calc_col
      endif
    endif
  endif
  let lnum = max([1, get(a:config, 'index', 0) + 1])
  let zindex = get(a:config, 'zindex', 50)
  " use exists
  if a:winid && coc#float#valid(a:winid)
    if s:is_vim
      let [line, col] = s:popup_position(a:config)
      let opts = {
            \ 'firstline': 1,
            \ 'line': line,
            \ 'col': col,
            \ 'minwidth': a:config['width'],
            \ 'minheight': a:config['height'],
            \ 'maxwidth': a:config['width'],
            \ 'maxheight': a:config['height'],
            \ 'title': get(a:config, 'title', ''),
            \ 'highlight': get(a:config, 'highlight', 'CocFloating'),
            \ 'borderhighlight':  [s:get_borderhighlight(a:config)],
            \ }
      if !s:empty_border(get(a:config, 'border', []))
        let opts['border'] = a:config['border']
      endif
      call popup_setoptions(a:winid, opts)
      call win_execute(a:winid, 'exe '.lnum)
      call coc#float#vim_buttons(a:winid, a:config)
      call s:add_highlights(a:winid, a:config, 0)
      return [a:winid, winbufnr(a:winid)]
    else
      let config = s:convert_config_nvim(a:config, 0)
      let hlgroup = get(a:config, 'highlight', 'CocFloating')
      let current = getwinvar(a:winid, '&winhl', '')
      let winhl = coc#util#merge_winhl(current, [['Normal', hlgroup], ['FoldColumn', hlgroup]])
      if winhl !=# current
        call setwinvar(a:winid, '&winhl', winhl)
      endif
      call nvim_win_set_buf(a:winid, bufnr)
      call nvim_win_set_config(a:winid, config)
      call nvim_win_set_cursor(a:winid, [lnum, 0])
      call coc#float#nvim_create_related(a:winid, config, a:config)
      call s:add_highlights(a:winid, a:config, 0)
      return [a:winid, bufnr]
    endif
  endif
  let winid = 0
  if s:is_vim
    let [line, col] = s:popup_position(a:config)
    let title = get(a:config, 'title', '')
    let buttons = get(a:config, 'buttons', [])
    let hlgroup = get(a:config, 'highlight',  'CocFloating')
    let nopad = get(a:config, 'nopad', 0)
    let border = s:empty_border(get(a:config, 'border', [])) ? [0, 0, 0, 0] : a:config['border']
    let opts = {
          \ 'title': title,
          \ 'line': line,
          \ 'col': col,
          \ 'fixed': 1,
          \ 'padding': [0, !nopad && !border[1], 0, !nopad && !border[3]],
          \ 'borderchars': s:get_borderchars(a:config),
          \ 'highlight': hlgroup,
          \ 'minwidth': a:config['width'],
          \ 'minheight': a:config['height'],
          \ 'maxwidth': a:config['width'],
          \ 'maxheight': a:config['height'],
          \ 'close': get(a:config, 'close', 0) ? 'button' : 'none',
          \ 'border': border,
          \ 'zindex': zindex,
          \ 'callback': { -> coc#float#on_close(winid)},
          \ 'borderhighlight': [s:get_borderhighlight(a:config)],
          \ 'scrollbarhighlight': 'CocFloatSbar',
          \ 'thumbhighlight': 'CocFloatThumb',
          \ }
    if type(get(a:config, 'filter', v:null)) == v:t_func
      let opts['filter'] = get(a:config, 'filter', v:null)
    endif
    noa let winid = popup_create(bufnr, opts)
    call s:set_float_defaults(winid, a:config)
    call win_execute(winid, 'exe '.lnum)
    call coc#float#vim_buttons(winid, a:config)
  else
    let config = s:convert_config_nvim(a:config, 1)
    noa let winid = nvim_open_win(bufnr, 0, config)
    if winid is 0
      return []
    endif
    " cursorline highlight not work on old neovim
    call s:set_float_defaults(winid, a:config)
    call nvim_win_set_cursor(winid, [lnum, 0])
    call coc#float#nvim_create_related(winid, config, a:config)
    call coc#float#nvim_set_winblend(winid, get(a:config, 'winblend', v:null))
  endif
  call s:add_highlights(winid, a:config, 1)
  let g:coc_last_float_win = winid
  call coc#util#do_autocmd('CocOpenFloat')
  return [winid, bufnr]
endfunction

function! coc#float#nvim_create_related(winid, config, opts) abort
  let related = getwinvar(a:winid, 'related', [])
  let exists = !empty(related)
  let border = get(a:opts, 'border', [])
  let borderhighlight = s:get_borderhighlight(a:opts)
  let buttons = get(a:opts, 'buttons', [])
  let pad = !get(a:opts, 'nopad', 0) && (empty(border) || get(border, 1, 0) == 0)
  let shadow = get(a:opts, 'shadow', 0)
  if get(a:opts, 'close', 0)
    call coc#float#nvim_close_btn(a:config, a:winid, border, borderhighlight, related)
  elseif exists
    call coc#float#close_related(a:winid, 'close')
  endif
  if !empty(buttons)
    call coc#float#nvim_buttons(a:config, a:winid, buttons, get(a:opts, 'getchar', 0), get(border, 2, 0), pad, borderhighlight, shadow, related)
  elseif exists
    call coc#float#close_related(a:winid, 'buttons')
  endif
  if !s:empty_border(border)
    let borderchars = s:get_borderchars(a:opts)
    call coc#float#nvim_border_win(a:config, borderchars, a:winid, border, get(a:opts, 'title', ''), !empty(buttons), borderhighlight, shadow, related)
  elseif exists
    call coc#float#close_related(a:winid, 'border')
  endif
  " Check right border
  if pad
    call coc#float#nvim_right_pad(a:config, a:winid, shadow, related)
  elseif exists
    call coc#float#close_related(a:winid, 'pad')
  endif
  call setwinvar(a:winid, 'related', filter(related, 'nvim_win_is_valid(v:val)'))
endfunction

" border window for neovim, content config with border
function! coc#float#nvim_border_win(config, borderchars, winid, border, title, hasbtn, hlgroup, shadow, related) abort
  let winid = coc#float#get_related(a:winid, 'border')
  let row = a:border[0] ? a:config['row'] - 1 : a:config['row']
  let col = a:border[3] ? a:config['col'] - 1 : a:config['col']
  let width = a:config['width'] + a:border[1] + a:border[3]
  let height = a:config['height'] + a:border[0] + a:border[2] + (a:hasbtn ? 2 : 0)
  let lines = coc#float#create_border_lines(a:border, a:borderchars, a:title, a:config['width'], a:config['height'], a:hasbtn)
  let bufnr = winid ? winbufnr(winid) : 0
  let bufnr = coc#float#create_buf(bufnr, lines)
  let opt = {
        \ 'relative': a:config['relative'],
        \ 'width': width,
        \ 'height': height,
        \ 'row': row,
        \ 'col': col,
        \ 'focusable': v:false,
        \ 'style': 'minimal',
        \ }
  if has_key(a:config, 'zindex')
    let opt['zindex'] = a:config['zindex']
  endif
  if a:shadow && !a:hasbtn && a:border[2]
    let opt['border'] = 'shadow'
  endif
  if winid
    call nvim_win_set_config(winid, opt)
    call setwinvar(winid, '&winhl', 'Normal:'.a:hlgroup)
  else
    noa let winid = nvim_open_win(bufnr, 0, opt)
    call setwinvar(winid, 'delta', -1)
    let winhl = 'Normal:'.a:hlgroup
    call s:nvim_add_related(winid, a:winid, 'border', winhl, a:related)
  endif
endfunction

" neovim only
function! coc#float#nvim_close_btn(config, winid, border, hlgroup, related) abort
  let winid = coc#float#get_related(a:winid, 'close')
  let config = {
        \ 'relative': a:config['relative'],
        \ 'width': 1,
        \ 'height': 1,
        \ 'row': get(a:border, 0, 0) ? a:config['row'] - 1 : a:config['row'],
        \ 'col': a:config['col'] + a:config['width'],
        \ 'focusable': v:true,
        \ 'style': 'minimal',
        \ }
  if has_key(a:config, 'zindex')
    let config['zindex'] = a:config['zindex'] + 2
  endif
  if winid
    call nvim_win_set_config(winid, coc#dict#pick(config, ['relative', 'row', 'col']))
  else
    let bufnr = coc#float#create_buf(0, ['X'])
    noa let winid = nvim_open_win(bufnr, 0, config)
    let winhl = 'Normal:'.a:hlgroup
    call setwinvar(winid, 'delta', -1)
    call s:nvim_add_related(winid, a:winid, 'close', winhl, a:related)
  endif
endfunction

" Create padding window by config of current window & border config
function! coc#float#nvim_right_pad(config, winid, shadow, related) abort
  let winid = coc#float#get_related(a:winid, 'pad')
  let config = {
        \ 'relative': a:config['relative'],
        \ 'width': 1,
        \ 'height': a:config['height'],
        \ 'row': a:config['row'],
        \ 'col': a:config['col'] + a:config['width'],
        \ 'focusable': v:false,
        \ 'style': 'minimal',
        \ }
  if has_key(a:config, 'zindex')
    let config['zindex'] = a:config['zindex'] + 1
  endif
  if a:shadow
    let config['border'] = 'shadow'
  endif
  if winid && nvim_win_is_valid(winid)
    call nvim_win_set_config(winid, coc#dict#pick(config, ['relative', 'row', 'col']))
    call nvim_win_set_height(winid, config['height'])
    return
  endif
  let s:pad_bufnr = bufloaded(s:pad_bufnr) ? s:pad_bufnr : coc#float#create_buf(0, repeat([''], &lines), 'hide')
  noa let winid = nvim_open_win(s:pad_bufnr, 0, config)
  call s:nvim_add_related(winid, a:winid, 'pad', '', a:related)
endfunction

" draw buttons window for window with config
function! coc#float#nvim_buttons(config, winid, buttons, getchar, borderbottom, pad, borderhighlight, shadow, related) abort
  let winid = coc#float#get_related(a:winid, 'buttons')
  let width = a:config['width'] + (a:pad ? 1 : 0)
  let config = {
        \ 'row': a:config['row'] + a:config['height'],
        \ 'col': a:config['col'],
        \ 'width': width,
        \ 'height': 2 + (a:borderbottom ? 1 : 0),
        \ 'relative': a:config['relative'],
        \ 'focusable': 1,
        \ 'style': 'minimal',
        \ 'zindex': 300,
        \ }
  if a:shadow
    let config['border'] = 'shadow'
  endif
  if winid
    let bufnr = winbufnr(winid)
    call s:create_btns_buffer(bufnr, width, a:buttons, a:borderbottom)
    call nvim_win_set_config(winid, config)
  else
    let bufnr = s:create_btns_buffer(0, width, a:buttons, a:borderbottom)
    noa let winid = nvim_open_win(bufnr, 0, config)
    if winid
      call s:nvim_add_related(winid, a:winid, 'buttons', '', a:related)
      call s:nvim_create_keymap(winid)
    endif
  endif
  if bufnr
    call nvim_buf_clear_namespace(bufnr, -1, 0, -1)
    call nvim_buf_add_highlight(bufnr, 1, a:borderhighlight, 0, 0, -1)
    if a:borderbottom
      call nvim_buf_add_highlight(bufnr, 1, a:borderhighlight, 2, 0, -1)
    endif
    let vcols = getbufvar(bufnr, 'vcols', [])
    " TODO need change vol to col
    for col in vcols
      call nvim_buf_add_highlight(bufnr, 1, a:borderhighlight, 1, col, col + 3)
    endfor
    if a:getchar
      let keys = s:gen_filter_keys(getbufline(bufnr, 2)[0])
      call matchaddpos('MoreMsg', map(keys[0], "[2,v:val]"), 99, -1, {'window': winid})
      call timer_start(10, {-> coc#float#getchar(winid, keys[1])})
    endif
  endif
endfunction

function! coc#float#getchar(winid, keys) abort
  let ch = coc#prompt#getc()
  let target = getwinvar(a:winid, 'target_winid', 0)
  if ch ==# "\<esc>"
    call coc#float#close(target)
    return
  endif
  if ch ==# "\<LeftMouse>"
    if getwinvar(v:mouse_winid, 'kind', '') ==# 'close'
      call coc#float#close(target)
      return
    endif
    if v:mouse_winid == a:winid && v:mouse_lnum == 2
      let vcols = getbufvar(winbufnr(a:winid), 'vcols', [])
      let col = v:mouse_col - 1
      if index(vcols, col) < 0
        let filtered = filter(vcols, 'v:val < col')
        call coc#rpc#notify('FloatBtnClick', [winbufnr(target), len(filtered)])
        call coc#float#close(target)
        return
      endif
    endif
  else
    let idx = index(a:keys, ch)
    if idx >= 0
      call coc#rpc#notify('FloatBtnClick', [winbufnr(target), idx])
      call coc#float#close(target)
      return
    endif
  endif
  call coc#float#getchar(a:winid, a:keys)
endfunction

" Create or refresh scrollbar for winid
" Need called on create, config, buffer change, scrolled
function! coc#float#nvim_scrollbar(winid) abort
  if s:is_vim
    return
  endif
  let winids = nvim_tabpage_list_wins(nvim_get_current_tabpage())
  if index(winids, a:winid) == -1
    return
  endif
  let config = nvim_win_get_config(a:winid)
  let [row, column] = nvim_win_get_position(a:winid)
  let relative = 'editor'
  if row == 0 && column == 0
    " fix bad value when ext_multigrid is enabled. https://github.com/neovim/neovim/issues/11935
    let [row, column] = [config.row, config.col]
    let relative = config.relative
  endif
  let width = nvim_win_get_width(a:winid)
  let height = nvim_win_get_height(a:winid)
  let bufnr = winbufnr(a:winid)
  let cw = getwinvar(a:winid, '&foldcolumn', 0) ? width - 1 : width
  let ch = coc#float#content_height(bufnr, cw, getwinvar(a:winid, '&wrap'))
  let closewin = coc#float#get_related(a:winid, 'close')
  let border = getwinvar(a:winid, 'border', [])
  let scrollinside = getwinvar(a:winid, 'scrollinside', 0) && get(border, 1, 0)
  let winblend = getwinvar(a:winid, '&winblend', 0)
  let move_down = closewin && !get(border, 0, 0)
  let id = coc#float#get_related(a:winid, 'scrollbar')
  if ch <= height || height <= 1
    " no scrollbar, remove exists
    if id
      call s:close_win(id, 1)
    endif
    return
  endif
  if move_down
    let height = height - 1
  endif
  call coc#float#close_related(a:winid, 'pad')
  let sbuf = id ? winbufnr(id) : 0
  let sbuf = coc#float#create_buf(sbuf, repeat([' '], height))
  let opts = {
        \ 'row': move_down ? row + 1 : row,
        \ 'col': column + width - scrollinside,
        \ 'relative': relative,
        \ 'width': 1,
        \ 'height': height,
        \ 'focusable': v:false,
        \ 'style': 'minimal',
        \ }
  if has_key(config, 'zindex')
    let opts['zindex'] = config['zindex'] + 2
  endif
  if s:has_shadow(config)
    let opts['border'] = 'shadow'
  endif
  if id
    call nvim_win_set_config(id, opts)
  else
    noa let id = nvim_open_win(sbuf, 0 , opts)
    if id == 0
      return
    endif
    if winblend
      call setwinvar(id, '&winblend', winblend)
    endif
    call setwinvar(id, 'kind', 'scrollbar')
    call setwinvar(id, 'target_winid', a:winid)
    call coc#float#add_related(id, a:winid)
  endif
  if !scrollinside
    call coc#float#nvim_scroll_adjust(a:winid)
  endif
  " The min with height - 1 ensures that the scrollbar never takes up the full height.
  " If ch <= height we never reach this point, so we always want an actual scrollbar here.
  " The height of the scrollbar needs to be an integer to conform to the terminal grid.
  " Rounding down could result in gaps appearing when using coc#float#scroll(1),
  " meaning a situation where the lower end of the scrollbar is above a certain position,
  " and after calling coc#float#scroll(1) the upper end of the scrollbar is below this position,
  " so the position is never part of the scrollbar,
  " giving the appearance that some of the text in the float is skipped.
  " Rounding up ensures that no such gaps can appear.
  let thumb_height = min([height - 1, float2nr(ceil(height * (height + 0.0)/ch))])
  let wininfo = getwininfo(a:winid)[0]
  let start = 0
  if wininfo['topline'] != 1
    " needed for correct getwininfo
    let firstline = wininfo['topline']
    let lastline = s:nvim_get_botline(firstline, height, cw, bufnr)
    let linecount = nvim_buf_line_count(winbufnr(a:winid))
    if lastline >= linecount
      let start = height - thumb_height
    else
      let start = max([1, float2nr(round((height - thumb_height + 0.0)*(firstline - 1.0)/(ch - height)))])
    endif
  endif
  " add highlights
  call nvim_buf_clear_namespace(sbuf, -1, 0, -1)
  for idx in range(0, height - 1)
    if idx >= start && idx < start + thumb_height
      call nvim_buf_add_highlight(sbuf, -1, 'CocFloatThumb', idx, 0, 1)
    else
      call nvim_buf_add_highlight(sbuf, -1, 'CocFloatSbar', idx, 0, 1)
    endif
  endfor
endfunction

function! coc#float#create_border_lines(border, borderchars, title, width, height, hasbtn) abort
  let borderchars = a:borderchars
  let list = []
  if a:border[0]
    let top = (a:border[3] ?  borderchars[4]: '')
          \.repeat(borderchars[0], a:width)
          \.(a:border[1] ? borderchars[5] : '')
    if !empty(a:title)
      let top = coc#string#compose(top, 1, a:title.' ')
    endif
    call add(list, top)
  endif
  let mid = (a:border[3] ?  borderchars[3]: '')
        \.repeat(' ', a:width)
        \.(a:border[1] ? borderchars[1] : '')
  call extend(list, repeat([mid], a:height + (a:hasbtn ? 2 : 0)))
  if a:hasbtn
    let list[len(list) - 2] = (a:border[3] ?  s:borderjoinchars[3]: '')
        \.repeat(' ', a:width)
        \.(a:border[1] ? s:borderjoinchars[1] : '')
  endif
  if a:border[2]
    let bot = (a:border[3] ?  borderchars[7]: '')
          \.repeat(borderchars[2], a:width)
          \.(a:border[1] ? borderchars[6] : '')
    call add(list, bot)
  endif
  return list
endfunction

" Close float window by id
function! coc#float#close(winid, ...) abort
  let noautocmd = get(a:, 1, 0)
  if a:winid >= 0
    call coc#float#close_related(a:winid)
    call s:close_win(a:winid, noautocmd)
  endif
  return 1
endfunction

" Get visible float windows
function! coc#float#get_float_win_list(...) abort
  let res = []
  let list_all = get(a:, 1, 0)
  if s:is_vim
    return filter(popup_list(), 'popup_getpos(v:val)["visible"]'.(list_all ? '' : '&& getwinvar(v:val, "float", 0)'))
  else
    let res = []
    for i in range(1, winnr('$'))
      let id = win_getid(i)
      let config = nvim_win_get_config(id)
      if empty(config) || empty(config['relative'])
        continue
      endif
      " ignore border & button window & others
      if list_all == 0 && !getwinvar(id, 'float', 0)
        continue
      endif
      call add(res, id)
    endfor
    return res
  endif
  return []
endfunction

function! coc#float#get_float_by_kind(kind) abort
  if s:is_vim
    return get(filter(popup_list(), 'popup_getpos(v:val)["visible"] && getwinvar(v:val, "kind", "") ==# "'.a:kind.'"'), 0, 0)
  else
    let res = []
    for i in range(1, winnr('$'))
      let winid = win_getid(i)
      let config = nvim_win_get_config(winid)
      if !empty(config['relative']) && getwinvar(winid, 'kind', '') ==# a:kind
        return winid
      endif
    endfor
  endif
  return 0
endfunction

" Check if a float window is scrollable
function! coc#float#scrollable(winid) abort
  let bufnr = winbufnr(a:winid)
  if bufnr == -1
    return 0
  endif
  if s:is_vim
    let pos = popup_getpos(a:winid)
    if get(pos, 'scrollbar', 0)
      return 1
    endif
    let ch = coc#float#content_height(bufnr, pos['core_width'], getwinvar(a:winid, '&wrap'))
    return ch > pos['core_height']
  else
    let height = nvim_win_get_height(a:winid)
    let width = nvim_win_get_width(a:winid)
    if width > 1 && getwinvar(a:winid, '&foldcolumn', 0)
      " since we use foldcolumn for left padding
      let width = width - 1
    endif
    let ch = coc#float#content_height(bufnr, width, getwinvar(a:winid, '&wrap'))
    return ch > height
  endif
endfunction

function! coc#float#has_scroll() abort
  let win_ids = filter(coc#float#get_float_win_list(), 'coc#float#scrollable(v:val)')
  return !empty(win_ids)
endfunction

function! coc#float#scroll(forward, ...)
  let amount = get(a:, 1, 0)
  let winids = filter(coc#float#get_float_win_list(), 'coc#float#scrollable(v:val) && getwinvar(v:val,"kind","") !=# "pum"')
  if empty(winids)
    return mode() =~ '^i' || mode() ==# 'v' ? "" : "\<Ignore>"
  endif
  for winid in winids
    call s:scroll_win(winid, a:forward, amount)
  endfor
  return mode() =~ '^i' || mode() ==# 'v' ? "" : "\<Ignore>"
endfunction

function! coc#float#scroll_win(winid, forward, amount) abort
  let opts = coc#float#get_options(a:winid)
  let lines = getbufline(winbufnr(a:winid), 1, '$')
  let maxfirst = s:max_firstline(lines, opts['height'], opts['width'])
  let topline = opts['topline']
  let height = opts['height']
  let width = opts['width']
  let scrolloff = getwinvar(a:winid, '&scrolloff', 0)
  if a:forward && topline >= maxfirst
    return
  endif
  if !a:forward && topline == 1
    return
  endif
  if a:amount == 0
    let topline = s:get_topline(opts['topline'], lines, a:forward, height, width)
  else
    let topline = topline + (a:forward ? a:amount : - a:amount)
  endif
  let topline = a:forward ? min([maxfirst, topline]) : max([1, topline])
  let lnum = s:get_cursorline(topline, lines, scrolloff, width, height)
  call s:win_setview(a:winid, topline, lnum)
  let top = coc#float#get_options(a:winid)['topline']
  " not changed
  if top == opts['topline']
    if a:forward
      call s:win_setview(a:winid, topline + 1, lnum + 1)
    else
      call s:win_setview(a:winid, topline - 1, lnum - 1)
    endif
  endif
endfunction

function! coc#float#content_height(bufnr, width, wrap) abort
  if !bufloaded(a:bufnr)
    return 0
  endif
  if !a:wrap
    return coc#compat#buf_line_count(a:bufnr)
  endif
  let lines = s:is_vim ? getbufline(a:bufnr, 1, '$') : nvim_buf_get_lines(a:bufnr, 0, -1, 0)
  return coc#string#content_height(lines, a:width)
endfunction

function! coc#float#nvim_refresh_scrollbar(winid) abort
  let id = coc#float#get_related(a:winid, 'scrollbar')
  if id && nvim_win_is_valid(id)
    call coc#float#nvim_scrollbar(a:winid)
  endif
endfunction

function! coc#float#on_close(winid) abort
  let winids = coc#float#get_float_win_list()
  for winid in winids
    let target = getwinvar(winid, 'target_winid', -1)
    if target == a:winid
      call coc#float#close(winid)
    endif
  endfor
endfunction

" Close related windows, or specific kind
function! coc#float#close_related(winid, ...) abort
  if !coc#float#valid(a:winid)
    return
  endif
  let timer = coc#window#get_var(a:winid, 'timer', 0)
  if timer
    call timer_stop(timer)
  endif
  let kind = get(a:, 1, '')
  let winids = coc#window#get_var(a:winid, 'related', [])
  for id in winids
    let curr = coc#window#get_var(id, 'kind', '')
    if empty(kind) || curr ==# kind
      if curr == 'list'
        call coc#float#close(id, 1)
      elseif s:is_vim
        " vim doesn't throw
        noa call popup_close(id)
      else
        silent! noa call nvim_win_close(id, 1)
      endif
    endif
  endfor
endfunction

" Close related windows if target window is not visible.
function! coc#float#check_related() abort
  let invalids = []
  let ids = coc#float#get_float_win_list(1)
  for id in ids
    let target = getwinvar(id, 'target_winid', 0)
    if target && index(ids, target) == -1
      call add(invalids, id)
    endif
  endfor
  for id in invalids
    call coc#float#close(id)
  endfor
endfunction

" Show float window/popup for user confirm.
" Create buttons popup on vim
function! coc#float#vim_buttons(winid, config) abort
  let related = getwinvar(a:winid, 'related', [])
  let winid = coc#float#get_related(a:winid, 'buttons')
  let btns = get(a:config, 'buttons', [])
  if empty(btns)
    if winid
      call s:close_win(winid, 1)
      " fix padding
      let opts = popup_getoptions(a:winid)
      let padding = get(opts, 'padding', v:null)
      if !empty(padding)
        let padding[2] = padding[2] - 2
      endif
      call popup_setoptions(a:winid, {'padding': padding})
    endif
    return
  endif
  let border = get(a:config, 'border', v:null)
  if !winid
    " adjusting popup padding
    let opts = popup_getoptions(a:winid)
    let padding = get(opts, 'padding', v:null)
    if type(padding) == 7
      let padding = [0, 0, 2, 0]
    elseif len(padding) == 0
      let padding = [1, 1, 3, 1]
    else
      let padding[2] = padding[2] + 2
    endif
    call popup_setoptions(a:winid, {'padding': padding})
  endif
  let borderhighlight = get(get(a:config, 'borderhighlight', []), 0, '')
  let pos = popup_getpos(a:winid)
  let bw = empty(border) ? 0 : get(border, 1, 0) + get(border, 3, 0)
  let borderbottom = empty(border) ? 0 : get(border, 2, 0)
  let borderleft = empty(border) ? 0 : get(border, 3, 0)
  let width = pos['width'] - bw + get(pos, 'scrollbar', 0)
  let bufnr = s:create_btns_buffer(winid ? winbufnr(winid): 0,width, btns, borderbottom)
  let height = 2 + (borderbottom ? 1 : 0)
  let keys = s:gen_filter_keys(getbufline(bufnr, 2)[0])
  let options = {
        \ 'filter': {id, key -> coc#float#vim_filter(id, key, keys[1])},
        \ 'highlight': get(opts, 'highlight', 'CocFloating')
        \ }
  let config = {
        \ 'line': pos['line'] + pos['height'] - height,
        \ 'col': pos['col'] + borderleft,
        \ 'minwidth': width,
        \ 'minheight': height,
        \ 'maxwidth': width,
        \ 'maxheight': height,
        \ }
  if winid != 0
    call popup_move(winid, config)
    call popup_setoptions(winid, options)
    call win_execute(winid, 'call clearmatches()')
  else
    let options = extend({
          \ 'filtermode': 'nvi',
          \ 'padding': [0, 0, 0, 0],
          \ 'fixed': 1,
          \ 'zindex': 99,
          \ }, options)
    call extend(options, config)
    let winid = popup_create(bufnr, options)
  endif
  if winid != 0
    if !empty(borderhighlight)
      call coc#highlight#add_highlight(bufnr, -1, borderhighlight, 0, 0, -1)
      call coc#highlight#add_highlight(bufnr, -1, borderhighlight, 2, 0, -1)
      call win_execute(winid, 'call matchadd("'.borderhighlight.'", "'.s:borderchars[1].'")')
    endif
    call setwinvar(winid, 'kind', 'buttons')
    call setwinvar(winid, 'target_winid', a:winid)
    call add(related, winid)
    call setwinvar(a:winid, 'related', related)
    call matchaddpos('MoreMsg', map(keys[0], "[2,v:val]"), 99, -1, {'window': winid})
  endif
endfunction

function! coc#float#nvim_float_click() abort
  let kind = getwinvar(win_getid(), 'kind', '')
  if kind == 'buttons'
    if line('.') != 2
      return
    endif
    let vw = strdisplaywidth(strpart(getline('.'), 0, col('.') - 1))
    let vcols = getbufvar(bufnr('%'), 'vcols', [])
    if index(vcols, vw) >= 0
      return
    endif
    let idx = 0
    if !empty(vcols)
      let filtered = filter(vcols, 'v:val < vw')
      let idx = idx + len(filtered)
    endif
    let winid = win_getid()
    let target = getwinvar(winid, 'target_winid', 0)
    if target
      call coc#rpc#notify('FloatBtnClick', [winbufnr(target), idx])
      call coc#float#close(target)
    endif
  elseif kind == 'close'
    let target = getwinvar(win_getid(), 'target_winid', 0)
    call coc#float#close(target)
  endif
endfunction

" Add <LeftRelease> mapping if necessary
function! coc#float#nvim_win_enter(winid) abort
  let kind = getwinvar(a:winid, 'kind', '')
  if kind == 'buttons' || kind == 'close'
    if empty(maparg('<LeftRelease>', 'n'))
      nnoremap <buffer><silent> <LeftRelease> :call coc#float#nvim_float_click()<CR>
    endif
  endif
endfunction

function! coc#float#vim_filter(winid, key, keys) abort
  let key = tolower(a:key)
  let idx = index(a:keys, key)
  let target = getwinvar(a:winid, 'target_winid', 0)
  if target && idx >= 0
    call coc#rpc#notify('FloatBtnClick', [winbufnr(target), idx])
    call coc#float#close(target)
    return 1
  endif
  return 0
endfunction

function! coc#float#get_related(winid, kind, ...) abort
  if coc#float#valid(a:winid)
    for winid in coc#window#get_var(a:winid, 'related', [])
      if coc#window#get_var(winid, 'kind', '') ==# a:kind
        return winid
      endif
    endfor
  endif
  return get(a:, 1, 0)
endfunction

function! coc#float#get_row(winid) abort
  let winid = s:is_vim ? a:winid : coc#float#get_related(a:winid, 'border', a:winid)
  if coc#float#valid(winid)
    if s:is_vim
      let pos = popup_getpos(winid)
      return pos['line'] - 1
    endif
    let pos = nvim_win_get_position(winid)
    return pos[0]
  endif
endfunction

" Create temporarily buffer with optional lines and &bufhidden
function! coc#float#create_buf(bufnr, ...) abort
  if a:bufnr > 0 && bufloaded(a:bufnr)
    let bufnr = a:bufnr
  else
    if s:is_vim
      noa let bufnr = bufadd('')
      noa call bufload(bufnr)
      call setbufvar(bufnr, '&buflisted', 0)
      call setbufvar(bufnr, '&modeline', 0)
      call setbufvar(bufnr, '&buftype', 'nofile')
      call setbufvar(bufnr, '&swapfile', 0)
    else
      noa let bufnr = nvim_create_buf(v:false, v:true)
    endif
    let bufhidden = get(a:, 2, 'wipe')
    call setbufvar(bufnr, '&bufhidden', bufhidden)
    call setbufvar(bufnr, '&undolevels', -1)
    " neovim's bug
    call setbufvar(bufnr, '&modifiable', 1)
  endif
  let lines = get(a:, 1, v:null)
  if type(lines) == v:t_list
    if s:is_vim
      silent noa call setbufline(bufnr, 1, lines)
      silent noa call deletebufline(bufnr, len(lines) + 1, '$')
    else
      call nvim_buf_set_lines(bufnr, 0, -1, v:false, lines)
    endif
  endif
  return bufnr
endfunction

" Change border window & close window when scrollbar is shown.
function! coc#float#nvim_scroll_adjust(winid) abort
  let winid = coc#float#get_related(a:winid, 'border')
  if !winid
    return
  endif
  let bufnr = winbufnr(winid)
  let lines = nvim_buf_get_lines(bufnr, 0, -1, 0)
  if len(lines) >= 2
    let cw = nvim_win_get_width(a:winid)
    let width = nvim_win_get_width(winid)
    if width - cw != 1 + (strcharpart(lines[1], 0, 1) ==# s:borderchars[3] ? 1 : 0)
      return
    endif
    call nvim_win_set_width(winid, width + 1)
    let lastline = len(lines) - 1
    for i in range(0, lastline)
      let line = lines[i]
      if i == 0
        let add = s:borderchars[0]
      elseif i == lastline
        let add = s:borderchars[2]
      else
        let add = ' '
      endif
      let prev = strcharpart(line, 0, strchars(line) - 1)
      let lines[i] = prev . add . coc#string#last_character(line)
    endfor
    call nvim_buf_set_lines(bufnr, 0, -1, 0, lines)
    " Move right close button
    if coc#window#get_var(a:winid, 'right', 0) == 0
      let id = coc#float#get_related(a:winid, 'close')
      if id
        let [row, col] = nvim_win_get_position(id)
        call nvim_win_set_config(id, {
              \ 'relative': 'editor',
              \ 'row': row,
              \ 'col': col + 1,
              \ })
      endif
    else
      " Move winid and all related left by 1
      let winids = [a:winid] + coc#window#get_var(a:winid, 'related', [])
      for winid in winids
        if nvim_win_is_valid(winid)
          if coc#window#get_var(winid, 'kind', '') != 'close'
            let config = nvim_win_get_config(winid)
            let [row, column] = [config.row, config.col]
            call nvim_win_set_config(winid, {
                  \ 'row': row,
                  \ 'col': column - 1,
                  \ 'relative': 'editor',
                  \ })
          endif
        endif
      endfor
    endif
  endif
endfunction

function! coc#float#nvim_set_winblend(winid, winblend) abort
  if a:winblend is v:null
    return
  endif
  call coc#window#set_var(a:winid, '&winblend', a:winblend)
  for winid in coc#window#get_var(a:winid, 'related', [])
    call coc#window#set_var(winid, '&winblend', a:winblend)
  endfor
endfunction

function! s:popup_visible(id) abort
  let pos = popup_getpos(a:id)
  if !empty(pos) && get(pos, 'visible', 0)
    return 1
  endif
  return 0
endfunction

function! s:convert_config_nvim(config, create) abort
  let valids = ['relative', 'win', 'anchor', 'width', 'height', 'bufpos', 'col', 'row', 'focusable']
  let result = coc#dict#pick(a:config, valids)
  let border = get(a:config, 'border', [])
  if !s:empty_border(border)
    if result['relative'] ==# 'cursor' && result['row'] < 0
      " move top when has bottom border
      if get(border, 2, 0)
        let result['row'] = result['row'] - 1
      endif
    else
      " move down when has top border
      if get(border, 0, 0) && !get(a:config, 'prompt', 0)
        let result['row'] = result['row'] + 1
      endif
    endif
    " move right when has left border
    if get(border, 3, 0)
      let result['col'] = result['col'] + 1
    endif
    let result['width'] = float2nr(result['width'] + 1 - get(border,3, 0))
  else
    let result['width'] = float2nr(result['width'] + (get(a:config, 'nopad', 0) ? 0 : 1))
  endif
  if get(a:config, 'shadow', 0) && a:create
    if empty(get(a:config, 'buttons', v:null)) && empty(get(border, 2, 0))
      let result['border'] = 'shadow'
    endif
  endif
  let result['zindex'] = get(a:config, 'zindex', 50)
  let result['height'] = float2nr(result['height'])
  return result
endfunction

function! s:create_btns_buffer(bufnr, width, buttons, borderbottom) abort
  let n = len(a:buttons)
  let spaces = a:width - n + 1
  let tw = 0
  for txt in a:buttons
    let tw += strdisplaywidth(txt)
  endfor
  if spaces < tw
    throw 'window is too small for buttons.'
  endif
  let ds = (spaces - tw)/n
  let dl = ds/2
  let dr = ds%2 == 0 ? ds/2 : ds/2 + 1
  let btnline = ''
  let idxes = []
  for idx in range(0, n - 1)
    let txt = toupper(a:buttons[idx][0]).a:buttons[idx][1:]
    let btnline .= repeat(' ', dl).txt.repeat(' ', dr)
    if idx != n - 1
      call add(idxes, strdisplaywidth(btnline))
      let btnline .= s:borderchars[1]
    endif
  endfor
  let lines = [repeat(s:borderchars[0], a:width), btnline]
  if a:borderbottom
    call add(lines, repeat(s:borderchars[0], a:width))
  endif
  for idx in idxes
    let lines[0] = strcharpart(lines[0], 0, idx).s:borderjoinchars[0].strcharpart(lines[0], idx + 1)
    if a:borderbottom
      let lines[2] = strcharpart(lines[0], 0, idx).s:borderjoinchars[2].strcharpart(lines[0], idx + 1)
    endif
  endfor
  let bufnr = coc#float#create_buf(a:bufnr, lines)
  call setbufvar(bufnr, 'vcols', idxes)
  return bufnr
endfunction

function! s:gen_filter_keys(line) abort
  let cols = []
  let used = []
  let next = 1
  for idx in  range(0, strchars(a:line) - 1)
    let ch = strcharpart(a:line, idx, 1)
    let nr = char2nr(ch)
    if next
      if (nr >= 65 && nr <= 90) || (nr >= 97 && nr <= 122)
        let lc = tolower(ch)
        if index(used, lc) < 0 && (!s:is_vim || empty(maparg(lc, 'n')))
          let col = len(strcharpart(a:line, 0, idx)) + 1
          call add(used, lc)
          call add(cols, col)
          let next = 0
        endif
      endif
    else
      if ch == s:borderchars[1]
        let next = 1
      endif
    endif
  endfor
  return [cols, used]
endfunction

function! s:close_win(winid, noautocmd) abort
  if a:winid <= 0
    return
  endif
  " vim not throw for none exists winid
  if s:is_vim
    let prefix = a:noautocmd ? 'noa ': ''
    exe prefix.'call popup_close('.a:winid.')'
  else
    if nvim_win_is_valid(a:winid)
      let prefix = a:noautocmd ? 'noa ': ''
      exe prefix.'call nvim_win_close('.a:winid.', 1)'
    endif
  endif
endfunction

function! s:nvim_create_keymap(winid) abort
  let bufnr = winbufnr(a:winid)
  call nvim_buf_set_keymap(bufnr, 'n', '<LeftRelease>', ':call coc#float#nvim_float_click()<CR>', {
        \ 'silent': v:true,
        \ 'nowait': v:true
        \ })
endfunction

" getwininfo is buggy on neovim, use topline, width & height should for content
function! s:nvim_get_botline(topline, height, width, bufnr) abort
  let lines = getbufline(a:bufnr, a:topline, a:topline + a:height - 1)
  let botline = a:topline
  let count = 0
  for i in range(0, len(lines) - 1)
    let w = max([1, strdisplaywidth(lines[i])])
    let lh = float2nr(ceil(str2float(string(w))/a:width))
    let count = count + lh
    let botline = a:topline + i
    if count >= a:height
      break
    endif
  endfor
  return botline
endfunction

" get popup position for vim8 based on config of neovim float window
function! s:popup_position(config) abort
  let relative = get(a:config, 'relative', 'editor')
  let border = get(a:config, 'border', [0, 0, 0, 0])
  let delta = get(border, 0, 0)  + get(border, 2, 0)
  if relative ==# 'cursor'
    if a:config['row'] < 0
      let delta = - delta
    elseif a:config['row'] == 0
      let delta = - get(border, 0, 0)
    else
      let delta = 0
    endif
    return [s:popup_cursor(a:config['row'] + delta), s:popup_cursor(a:config['col'])]
  endif
  return [a:config['row'] + 1, a:config['col'] + 1]
endfunction

function! coc#float#add_related(winid, target) abort
  let arr = coc#window#get_var(a:target, 'related', [])
  if index(arr, a:winid) >= 0
    return
  endif
  call add(arr, a:winid)
  call coc#window#set_var(a:target, 'related', arr)
endfunction

function! coc#float#get_wininfo(winid) abort
  if !coc#float#valid(a:winid)
    throw 'Not valid float window: '.a:winid
  endif
  if s:is_vim
    let pos = popup_getpos(a:winid)
    return {'topline': pos['firstline'], 'botline': pos['lastline']}
  endif
  let info = getwininfo(a:winid)[0]
  return {'topline': info['topline'], 'botline': info['botline']}
endfunction

function! s:popup_cursor(n) abort
  if a:n == 0
    return 'cursor'
  endif
  if a:n < 0
    return 'cursor'.a:n
  endif
  return 'cursor+'.a:n
endfunction

" max firstline of lines, height > 0, width > 0
function! s:max_firstline(lines, height, width) abort
  let max = len(a:lines)
  let remain = a:height
  for line in reverse(copy(a:lines))
    let w = max([1, strdisplaywidth(line)])
    let dh = float2nr(ceil(str2float(string(w))/a:width))
    if remain - dh < 0
      break
    endif
    let remain = remain - dh
    let max = max - 1
  endfor
  return min([len(a:lines), max + 1])
endfunction

" Get best lnum by topline
function! s:get_cursorline(topline, lines, scrolloff, width, height) abort
  let lastline = len(a:lines)
  if a:topline == lastline
    return lastline
  endif
  let bottomline = a:topline
  let used = 0
  for lnum in range(a:topline, lastline)
    let w = max([1, strdisplaywidth(a:lines[lnum - 1])])
    let dh = float2nr(ceil(str2float(string(w))/a:width))
    if used + dh >= a:height || lnum == lastline
      let bottomline = lnum
      break
    endif
    let used += dh
  endfor
  let cursorline = a:topline + a:scrolloff
  if cursorline + a:scrolloff > bottomline
    " unable to satisfy scrolloff
    let cursorline = (a:topline + bottomline)/2
  endif
  return cursorline
endfunction

" Get firstline for full scroll
function! s:get_topline(topline, lines, forward, height, width) abort
  let used = 0
  let lnums = a:forward ? range(a:topline, len(a:lines)) : reverse(range(1, a:topline))
  let topline = a:forward ? len(a:lines) : 1
  for lnum in lnums
    let w = max([1, strdisplaywidth(a:lines[lnum - 1])])
    let dh = float2nr(ceil(str2float(string(w))/a:width))
    if used + dh >= a:height
      let topline = lnum
      break
    endif
    let used += dh
  endfor
  if topline == a:topline
    if a:forward
      let topline = min([len(a:lines), topline + 1])
    else
      let topline = max([1, topline - 1])
    endif
  endif
  return topline
endfunction

" topline content_height content_width
function! coc#float#get_options(winid) abort
  if s:is_vim
    let pos = popup_getpos(a:winid)
    return {
      \ 'topline': pos['firstline'],
      \ 'width': pos['core_width'],
      \ 'height': pos['core_height']
      \ }
  else
    let width = nvim_win_get_width(a:winid)
    if coc#window#get_var(a:winid, '&foldcolumn', 0)
      let width = width - 1
    endif
    let info = getwininfo(a:winid)[0]
    return {
      \ 'topline': info['topline'],
      \ 'height': nvim_win_get_height(a:winid),
      \ 'width': width
      \ }
  endif
endfunction

function! s:win_setview(winid, topline, lnum) abort
  if s:is_vim
    call win_execute(a:winid, 'exe '.a:lnum)
    call popup_setoptions(a:winid, { 'firstline': a:topline })
  else
    call win_execute(a:winid, 'call winrestview({"lnum":'.a:lnum.',"topline":'.a:topline.'})')
    call timer_start(1, { -> coc#float#nvim_refresh_scrollbar(a:winid) })
  endif
endfunction

function! s:set_float_defaults(winid, config) abort
  if !s:is_vim
    let hlgroup = get(a:config, 'highlight', 'CocFloating')
    call setwinvar(a:winid, '&winhl', 'Normal:'.hlgroup.',FoldColumn:'.hlgroup)
    call setwinvar(a:winid, 'border', get(a:config, 'border', []))
    call setwinvar(a:winid, 'scrollinside', get(a:config, 'scrollinside', 0))
    call setwinvar(a:winid, '&foldcolumn', s:nvim_get_foldcolumn(a:config))
    call setwinvar(a:winid, '&signcolumn', 'no')
    call setwinvar(a:winid, '&cursorcolumn', 0)
  else
    call setwinvar(a:winid, '&foldcolumn', 0)
  endif
  if exists('&statuscolumn')
    call setwinvar(a:winid, '&statuscolumn', '')
  endif
  if !s:is_vim
    call setwinvar(a:winid, '&number', 0)
    call setwinvar(a:winid, '&relativenumber', 0)
    call setwinvar(a:winid, '&cursorline', 0)
  endif
  call setwinvar(a:winid, '&foldenable', 0)
  call setwinvar(a:winid, '&colorcolumn', '')
  call setwinvar(a:winid, '&spell', 0)
  call setwinvar(a:winid, '&linebreak', 1)
  call setwinvar(a:winid, '&conceallevel', 0)
  call setwinvar(a:winid, '&list', 0)
  call setwinvar(a:winid, '&wrap', !get(a:config, 'cursorline', 0))
  call setwinvar(a:winid, '&scrolloff', 0)
  call setwinvar(a:winid, '&showbreak', 'NONE')
  call win_execute(a:winid, 'setl fillchars+=eob:\ ')
  if get(a:config, 'autohide', 0)
    call setwinvar(a:winid, 'autohide', 1)
  endif
  call setwinvar(a:winid, 'float', 1)
endfunction

function! s:nvim_add_related(winid, target, kind, winhl, related) abort
  if a:winid <= 0
    return
  endif
  if exists('&statuscolumn')
    call setwinvar(a:winid, '&statuscolumn', '')
  endif
  let winhl = empty(a:winhl) ? coc#window#get_var(a:target, '&winhl', '') : a:winhl
  call setwinvar(a:winid, '&winhl', winhl)
  call setwinvar(a:winid, 'target_winid', a:target)
  call setwinvar(a:winid, 'kind', a:kind)
  call add(a:related, a:winid)
endfunction

function! s:nvim_get_foldcolumn(config) abort
  let nopad = get(a:config, 'nopad', 0)
  if nopad
    return 0
  endif
  let border = get(a:config, 'border', v:null)
  if border is 1 || (type(border) == v:t_list && get(border, 3, 0) == 1)
    return 0
  endif
  return 1
endfunction

function! s:add_highlights(winid, config, create) abort
  let codes = get(a:config, 'codes', [])
  let highlights = get(a:config, 'highlights', [])
  if empty(codes) && empty(highlights) && a:create
    return
  endif
  let bgGroup = get(a:config, 'highlight', 'CocFloating')
  for obj in codes
    let hlGroup = get(obj, 'hlGroup', v:null)
    if !empty(hlGroup)
      let obj['hlGroup'] = coc#hlgroup#compose_hlgroup(hlGroup, bgGroup)
    endif
  endfor
  call coc#highlight#add_highlights(a:winid, codes, highlights)
endfunction

function! s:empty_border(border) abort
  if empty(a:border) || empty(filter(copy(a:border), 'v:val != 0'))
    return 1
  endif
  return 0
endfunction

function! s:get_borderchars(config) abort
  let borderchars = get(a:config, 'borderchars', [])
  if !empty(borderchars)
    return borderchars
  endif
  return get(a:config, 'rounded', 0) ? s:rounded_borderchars : s:borderchars
endfunction

function! s:scroll_win(winid, forward, amount) abort
  if s:is_vim
    call coc#float#scroll_win(a:winid, a:forward, a:amount)
  else
    call timer_start(0, { -> coc#float#scroll_win(a:winid, a:forward, a:amount)})
  endif
endfunction

function! s:get_borderhighlight(config) abort
  let hlgroup = get(a:config, 'highlight', 'CocFloating')
  let borderhighlight = get(a:config, 'borderhighlight', 'CocFloatBorder')
  let highlight = type(borderhighlight) == 3 ? borderhighlight[0] : borderhighlight
  return coc#hlgroup#compose_hlgroup(highlight, hlgroup)
endfunction

function! s:has_shadow(config) abort
  let border = get(a:config, 'border', [])
  let filtered = filter(copy(border), 'type(v:val) == 3 && get(v:val, 1, "") ==# "FloatShadow"')
  return len(filtered) > 0
endfunction
