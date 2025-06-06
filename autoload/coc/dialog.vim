scriptencoding utf-8
let s:is_vim = !has('nvim')
let s:root = expand('<sfile>:h:h:h')
let s:prompt_win_bufnr = 0
let s:list_win_bufnr = 0
let s:prompt_win_width = get(g:, 'coc_prompt_win_width', 32)
let s:frames = ['·  ', '·· ', '···', ' ··', '  ·', '   ']
let s:sign_group = 'PopUpCocDialog'
let s:detail_bufnr = 0
let s:term_support = s:is_vim ? has('terminal') : 1

" Float window aside pum
function! coc#dialog#create_pum_float(lines, config) abort
  let winid = coc#float#get_float_by_kind('pumdetail')
  if empty(a:lines) || !coc#pum#visible()
    if winid
      call coc#float#close(winid)
    endif
    return
  endif
  let pumbounding = coc#pum#info()
  let border = get(a:config, 'border', [])
  let pw = pumbounding['width'] + (pumbounding['border'] ? 0 : get(pumbounding, 'scrollbar', 0))
  let rp = &columns - pumbounding['col'] - pw
  let showRight = pumbounding['col'] > rp ? 0 : 1
  let maxWidth = showRight ? min([rp - 1, a:config['maxWidth']]) : min([pumbounding['col'] - 1, a:config['maxWidth']])
  let bh = get(border, 0 ,0) + get(border, 2, 0)
  let maxHeight = &lines - pumbounding['row'] - &cmdheight - 1 - bh
  if maxWidth <= 2 || maxHeight < 1
    return v:null
  endif
  let width = 0
  for line in a:lines
    let dw = max([1, strdisplaywidth(line)])
    let width = max([width, dw + 2])
  endfor
  let width = width < maxWidth ? width : maxWidth
  let ch = coc#string#content_height(a:lines, width - 2)
  let height = ch < maxHeight ? ch : maxHeight
  let lines = map(a:lines, {_, s -> s =~# '^─' ? repeat('─', width - 2 + (s:is_vim && ch > height ? -1 : 0)) : s})
  let opts = {
        \ 'lines': lines,
        \ 'highlights': get(a:config, 'highlights', []),
        \ 'relative': 'editor',
        \ 'col': showRight ? pumbounding['col'] + pw : pumbounding['col'] - width,
        \ 'row': pumbounding['row'],
        \ 'height': height,
        \ 'width': width - 2 + (s:is_vim && ch > height ? -1 : 0),
        \ 'scrollinside': showRight ? 0 : 1,
        \ 'codes': get(a:config, 'codes', []),
        \ }
  for key in ['border', 'highlight', 'borderhighlight', 'winblend', 'focusable', 'shadow', 'rounded', 'title']
    if has_key(a:config, key)
      let opts[key] = a:config[key]
    endif
  endfor
  call s:close_auto_hide_wins(winid)
  let result = coc#float#create_float_win(winid, s:detail_bufnr, opts)
  if empty(result)
    return
  endif
  let s:detail_bufnr = result[1]
  call setwinvar(result[0], 'kind', 'pumdetail')
  if !s:is_vim
    call coc#float#nvim_scrollbar(result[0])
  endif
endfunction

" Float window below/above cursor
function! coc#dialog#create_cursor_float(winid, bufnr, lines, config) abort
  if coc#prompt#activated()
    return v:null
  endif
  let pumAlignTop = get(a:config, 'pumAlignTop', 0)
  let modes = get(a:config, 'modes', ['n', 'i', 'ic', 's'])
  let mode = mode()
  let currbuf = bufnr('%')
  let pos = [line('.'), col('.')]
  if index(modes, mode) == -1
    return v:null
  endif
  let dimension = coc#dialog#get_config_cursor(a:lines, a:config)
  if empty(dimension)
    return v:null
  endif
  if coc#pum#visible() && ((pumAlignTop && dimension['row'] <0)|| (!pumAlignTop && dimension['row'] > 0))
    return v:null
  endif
  let width = dimension['width']
  let lines = map(a:lines, {_, s -> s =~# '^─' ? repeat('─', width) : s})
  let config = extend(extend({'lines': lines, 'relative': 'cursor'}, a:config), dimension)
  call s:close_auto_hide_wins(a:winid)
  let res = coc#float#create_float_win(a:winid, a:bufnr, config)
  if empty(res)
    return v:null
  endif
  let alignTop = dimension['row'] < 0
  let winid = res[0]
  let bufnr = res[1]
  call win_execute(winid, 'setl nonumber')
  if s:is_vim
    call timer_start(0, { -> execute('redraw')})
  else
    redraw
    call coc#float#nvim_scrollbar(winid)
  endif
  return [currbuf, pos, winid, bufnr, alignTop]
endfunction

" Use terminal buffer
function! coc#dialog#_create_prompt_vim(title, default, opts) abort
  execute 'hi link CocPopupTerminal '.get(a:opts, 'highlight', 'CocFloating')
  let node =  expand(get(g:, 'coc_node_path', 'node'))
  let placeHolder = get(a:opts, 'placeHolder', '')
  let opt = {
        \ 'term_rows': 1,
        \ 'hidden': 1,
        \ 'term_finish': 'close',
        \ 'norestore': 1,
        \ 'tty_type': 'conpty',
        \ 'term_highlight': 'CocPopupTerminal'
        \ }
  let bufnr = term_start([node, s:root . '/bin/prompt.js', a:default, empty(placeHolder) ? '' : placeHolder], opt)
  call term_setapi(bufnr, 'Coc')
  call setbufvar(bufnr, 'current', type(a:default) == v:t_string ? a:default : '')
  let res = s:create_prompt_win(bufnr, a:title, a:default, a:opts)
  if empty(res)
    return
  endif
  let winid = res[0]
  " call win_gotoid(winid)
  call coc#util#do_autocmd('CocOpenFloatPrompt')
  let pos = popup_getpos(winid)
  " width height row col
  let dimension = [pos['width'], pos['height'], pos['line'] - 1, pos['col'] - 1]
  return [bufnr, winid, dimension]
endfunction

" Use normal buffer on neovim
function! coc#dialog#_create_prompt_nvim(title, default, opts) abort
  let result = s:create_prompt_win(s:prompt_win_bufnr, a:title, a:default, a:opts)
  if empty(result)
    return
  endif
  let winid = result[0]
  let s:prompt_win_bufnr = result[1]
  let bufnr = s:prompt_win_bufnr
  call sign_unplace(s:sign_group, { 'buffer': s:prompt_win_bufnr })
  call nvim_set_current_win(winid)
  inoremap <buffer> <C-a> <Home>
  inoremap <buffer><expr><C-e> pumvisible() ? "\<C-e>" : "\<End>"
  exe 'imap <silent><nowait><buffer> <esc> <esc><esc>'
  exe 'nnoremap <silent><buffer> <esc> :call coc#float#close('.winid.')<CR>'
  exe 'inoremap <silent><expr><nowait><buffer> <cr> "\<C-r>=coc#dialog#prompt_insert()\<cr>\<esc>"'
  if get(a:opts, 'list', 0)
    for key in ['<C-j>', '<C-k>', '<C-n>', '<C-p>', '<up>', '<down>', '<C-f>', '<C-b>', '<C-space>']
      let escaped = key ==# '<C-space>' ? '\<C-@\>' : substitute(key, '\(<\|>\)', '\\\1', 'g')
      exe 'inoremap <nowait><buffer> '.key.' <Cmd>call coc#rpc#notify("PromptKeyPress", ['.bufnr.', "'.escaped.'"])<CR>'
    endfor
  endif
  let mode = mode()
  if mode ==# 'n'
    call feedkeys('A', 'int')
  elseif mode ==# 'i'
    call feedkeys("\<end>", 'int')
  else
    call feedkeys("\<esc>A", 'int')
  endif
  let placeHolder = get(a:opts, 'placeHolder', '')
  if empty(a:default) && !empty(placeHolder)
    let src_id = coc#highlight#create_namespace('input-box')
    call nvim_buf_set_extmark(bufnr, src_id, 0, 0, {
          \ 'virt_text': [[placeHolder, 'CocInputBoxVirtualText']],
          \ 'virt_text_pos': 'overlay',
          \ })
  endif
  call coc#util#do_autocmd('CocOpenFloatPrompt')
  let id = coc#float#get_related(winid, 'border')
  let pos = nvim_win_get_position(id)
  let dimension = [nvim_win_get_width(id), nvim_win_get_height(id), pos[0], pos[1]]
  return [bufnr, winid, dimension]
endfunction

" Create float window for input
function! coc#dialog#create_prompt_win(title, default, opts) abort
  call s:close_auto_hide_wins()
  if s:is_vim
    if !s:term_support
      " use popup_menu or inputlist instead
      let pickItems = get(a:opts, 'quickpick', [])
      if len(pickItems) > 0
        call coc#ui#quickpick(a:title, pickItems, {err, res -> s:on_quickpick_selected(err, res)})
      else
        call inputsave()
        let value = input(a:title.':', a:default)
        call inputrestore()
        if empty(value)
          " Cancel
          call timer_start(50, { -> coc#rpc#notify('CocAutocmd', ['BufWinLeave', -1, -1])})
        else
          call timer_start(50, { -> coc#rpc#notify('PromptInsert', [value, -1])})
        endif
      endif
      return [-1, -1, [0, 0, 0, 0]]
    endif
    return coc#dialog#_create_prompt_vim(a:title, a:default, a:opts)
  endif
  return  coc#dialog#_create_prompt_nvim(a:title, a:default, a:opts)
endfunction

" Create list window under target window
function! coc#dialog#create_list(target, dimension, opts) abort
  if a:target < 0
    return [-1, -1]
  endif
  let maxHeight = get(a:opts, 'maxHeight', 30)
  let height = get(a:opts, 'linecount', 1)
  let height = min([maxHeight, height, &lines - &cmdheight - 1 - a:dimension['row'] + a:dimension['height']])
  let chars = get(a:opts, 'rounded', 1) ? ['╯', '╰'] : ['┘', '└']
  let width = a:dimension['width'] - 2
  let config = extend(copy(a:opts), {
      \ 'relative': 'editor',
      \ 'row': a:dimension['row'] + a:dimension['height'],
      \ 'col': a:dimension['col'],
      \ 'width': width,
      \ 'height': height,
      \ 'border': [1, 1, 1, 1],
      \ 'scrollinside': 1,
      \ 'borderchars': extend(['─', '│', '─', '│', '├', '┤'], chars)
      \ })
  let bufnr = 0
  let result = coc#float#create_float_win(0, s:list_win_bufnr, config)
  if empty(result)
    return
  endif
  let winid = result[0]
  call coc#float#add_related(winid, a:target)
  call setwinvar(winid, 'auto_height', get(a:opts, 'autoHeight', 1))
  call setwinvar(winid, 'core_width', width)
  call setwinvar(winid, 'max_height', maxHeight)
  call setwinvar(winid, 'target_winid', a:target)
  call setwinvar(winid, 'kind', 'list')
  call coc#dialog#check_scroll_vim(a:target)
  return result
endfunction

" Create menu picker for pick single item
function! coc#dialog#create_menu(lines, config) abort
  call s:close_auto_hide_wins()
  let highlight = get(a:config, 'highlight', 'CocFloating')
  let borderhighlight = get(a:config, 'borderhighlight', [highlight])
  let relative = get(a:config, 'relative', 'cursor')
  let lines = a:lines
  let content = get(a:config, 'content', '')
  let maxWidth = get(a:config, 'maxWidth', 80)
  let highlights = get(a:config, 'highlights', [])
  let contentCount = 0
  if !empty(content)
    let contentLines = coc#string#reflow(split(content, '\r\?\n'), maxWidth)
    let contentCount = len(contentLines)
    let lines = extend(contentLines, lines)
    if !empty(highlights)
      for item in highlights
        let item['lnum'] = item['lnum'] + contentCount
      endfor
    endif
  endif
  let opts = {
    \ 'lines': lines,
    \ 'highlight': highlight,
    \ 'title': get(a:config, 'title', ''),
    \ 'borderhighlight': borderhighlight,
    \ 'maxWidth': maxWidth,
    \ 'maxHeight': get(a:config, 'maxHeight', 80),
    \ 'rounded': get(a:config, 'rounded', 0),
    \ 'border': [1, 1, 1, 1],
    \ 'highlights': highlights,
    \ 'relative': relative,
    \ }
  if relative ==# 'editor'
    let dimension = coc#dialog#get_config_editor(lines, opts)
  else
    let dimension = coc#dialog#get_config_cursor(lines, opts)
  endif
  call extend(opts, dimension)
  let ids = coc#float#create_float_win(0, s:prompt_win_bufnr, opts)
  if empty(ids)
    return
  endif
  let s:prompt_win_bufnr = ids[1]
  call coc#dialog#set_cursor(ids[0], ids[1], contentCount + 1)
  redraw
  if !s:is_vim
    call coc#float#nvim_scrollbar(ids[0])
  endif
  return [ids[0], ids[1], contentCount]
endfunction

" Create dialog at center of screen
function! coc#dialog#create_dialog(lines, config) abort
  call s:close_auto_hide_wins()
  " dialog always have borders
  let title = get(a:config, 'title', '')
  let buttons = get(a:config, 'buttons', [])
  let highlight = get(a:config, 'highlight', 'CocFloating')
  let borderhighlight = get(a:config, 'borderhighlight', [highlight])
  let opts = {
    \ 'title': title,
    \ 'rounded': get(a:config, 'rounded', 0),
    \ 'relative': 'editor',
    \ 'border': [1,1,1,1],
    \ 'close': get(a:config, 'close', 1),
    \ 'highlight': highlight,
    \ 'highlights': get(a:config, 'highlights', []),
    \ 'buttons': buttons,
    \ 'borderhighlight': borderhighlight,
    \ 'getchar': get(a:config, 'getchar', 0)
    \ }
  call extend(opts, coc#dialog#get_config_editor(a:lines, a:config))
  let bufnr = coc#float#create_buf(0, a:lines)
  let res =  coc#float#create_float_win(0, bufnr, opts)
  if empty(res)
    return
  endif
  if get(a:config, 'cursorline', 0)
    call coc#dialog#place_sign(bufnr, 1)
  endif
  if !s:is_vim
    redraw
    call coc#float#nvim_scrollbar(res[0])
  endif
  return res
endfunction

function! coc#dialog#prompt_confirm(title, cb) abort
  call s:close_auto_hide_wins()
  if s:is_vim && exists('*popup_dialog')
    try
      call popup_dialog(a:title. ' (y/n)?', {
        \ 'highlight': 'Normal',
        \ 'filter': 'popup_filter_yesno',
        \ 'callback': {id, res -> a:cb(v:null, res)},
        \ 'borderchars': get(g:, 'coc_borderchars', ['─', '│', '─', '│', '╭', '╮', '╯', '╰']),
        \ 'borderhighlight': ['MoreMsg']
        \ })
    catch /.*/
      call a:cb(v:exception)
    endtry
    return
  endif
  let text = ' '. a:title . ' (y/n)? '
  let maxWidth = coc#math#min(78, &columns - 2)
  let width = coc#math#min(maxWidth, strdisplaywidth(text))
  let maxHeight = &lines - &cmdheight - 1
  let height = coc#math#min(maxHeight, float2nr(ceil(str2float(string(strdisplaywidth(text)))/width)))
  let arr =  coc#float#create_float_win(0, s:prompt_win_bufnr, {
        \ 'col': &columns/2 - width/2 - 1,
        \ 'row': maxHeight/2 - height/2 - 1,
        \ 'width': width,
        \ 'height': height,
        \ 'border': [1,1,1,1],
        \ 'focusable': v:false,
        \ 'relative': 'editor',
        \ 'highlight': 'Normal',
        \ 'borderhighlight': 'MoreMsg',
        \ 'style': 'minimal',
        \ 'lines': [text],
        \ })
  if empty(arr)
    call a:cb('Window create failed!')
    return
  endif
  let winid = arr[0]
  let s:prompt_win_bufnr = arr[1]
  call sign_unplace(s:sign_group, { 'buffer': s:prompt_win_bufnr })
  let res = 0
  redraw
  " same result as vim
  while 1
    let key = nr2char(getchar())
    if key == "\<C-c>"
      let res = -1
      break
    elseif key == "\<esc>" || key == 'n' || key == 'N'
      let res = 0
      break
    elseif key == 'y' || key == 'Y'
      let res = 1
      break
    endif
  endw
  call coc#float#close(winid)
  call a:cb(v:null, res)
endfunction

" works on neovim only
function! coc#dialog#get_prompt_win() abort
  if s:prompt_win_bufnr == 0
    return -1
  endif
  return get(win_findbuf(s:prompt_win_bufnr), 0, -1)
endfunction

function! coc#dialog#get_config_editor(lines, config) abort
  let title = get(a:config, 'title', '')
  let maxheight = min([get(a:config, 'maxHeight', 78), &lines - &cmdheight - 6])
  let maxwidth = min([get(a:config, 'maxWidth', 78), &columns - 2])
  let buttons = get(a:config, 'buttons', [])
  let minwidth = s:min_btns_width(buttons)
  if maxheight <= 0 || maxwidth <= 0 || minwidth > maxwidth
    throw 'Not enough spaces for float window'
  endif
  let ch = 0
  let width = min([strdisplaywidth(title) + 1, maxwidth])
  for line in a:lines
    let dw = max([1, strdisplaywidth(line)])
    if dw < maxwidth && dw > width
      let width = dw
    elseif dw >= maxwidth
      let width = maxwidth
    endif
    let ch += float2nr(ceil(str2float(string(dw))/maxwidth))
  endfor
  let width = max([minwidth, width])
  let height = coc#math#min(ch ,maxheight)
  return {
      \ 'row': &lines/2 - (height + 4)/2,
      \ 'col': &columns/2 - (width + 2)/2,
      \ 'width': width,
      \ 'height': height,
      \ }
endfunction

function! coc#dialog#prompt_insert() abort
  let value = getline('.')
  call coc#rpc#notify('PromptInsert', [value, bufnr('%')])
  return ''
endfunction

" Dimension of window with lines relative to cursor
" Width & height excludes border & padding
function! coc#dialog#get_config_cursor(lines, config) abort
  let preferTop = get(a:config, 'preferTop', 0)
  let title = get(a:config, 'title', '')
  let border = get(a:config, 'border', [])
  if empty(border) && len(title)
    let border = [1, 1, 1, 1]
  endif
  let bh = get(border, 0, 0) + get(border, 2, 0)
  let vh = &lines - &cmdheight - 1
  if vh <= 0
    return v:null
  endif
  let maxWidth = coc#math#min(get(a:config, 'maxWidth', &columns - 1), &columns - 1)
  if maxWidth < 3
    return v:null
  endif
  let maxHeight = coc#math#min(get(a:config, 'maxHeight', vh), vh)
  let width = coc#math#min(40, strdisplaywidth(title)) + 3
  for line in a:lines
    let dw = max([1, strdisplaywidth(line)])
    let width = max([width, dw + 2])
  endfor
  let width = coc#math#min(maxWidth, width)
  let ch = coc#string#content_height(a:lines, width - 2)
  let [lineIdx, colIdx] = coc#cursor#screen_pos()
  " How much we should move left
  let offsetX = coc#math#min(get(a:config, 'offsetX', 0), colIdx)
  let showTop = 0
  let hb = vh - lineIdx -1
  if lineIdx > bh + 2 && (preferTop || (lineIdx > hb && hb < ch + bh))
    let showTop = 1
  endif
  let height = coc#math#min(maxHeight, ch + bh, showTop ? lineIdx - 1 : hb)
  if height <= bh
    return v:null
  endif
  let col = - max([offsetX, colIdx - (&columns - 1 - width)])
  let row = showTop ? - height + bh : 1
  return {
        \ 'row': row,
        \ 'col': col,
        \ 'width': width - 2,
        \ 'height': height - bh
        \ }
endfunction

function! coc#dialog#change_border_hl(winid, hlgroup) abort
  if !hlexists(a:hlgroup)
    return
  endif
  if s:is_vim
    if coc#float#valid(a:winid)
      call popup_setoptions(a:winid, {'borderhighlight': repeat([a:hlgroup], 4)})
      redraw
    endif
  else
    let winid = coc#float#get_related(a:winid, 'border')
    if winid > 0
      call setwinvar(winid, '&winhl', 'Normal:'.a:hlgroup)
    endif
  endif
endfunction

function! coc#dialog#change_title(winid, title) abort
  if s:is_vim
    if coc#float#valid(a:winid)
      call popup_setoptions(a:winid, {'title': a:title})
      redraw
    endif
  else
    let winid = coc#float#get_related(a:winid, 'border')
    if winid > 0
      let bufnr = winbufnr(winid)
      let line = getbufline(bufnr, 1)[0]
      let top = strcharpart(line, 0, 1)
            \.repeat('─', strchars(line) - 2)
            \.strcharpart(line, strchars(line) - 1, 1)
      if !empty(a:title)
        let top = coc#string#compose(top, 1, a:title.' ')
      endif
      call nvim_buf_set_lines(bufnr, 0, 1, v:false, [top])
    endif
  endif
endfunction

function! coc#dialog#change_input_value(winid, bufnr, value) abort
  if !coc#float#valid(a:winid)
    return
  endif
  if win_getid() != a:winid
    call win_gotoid(a:winid)
  endif
  if s:is_vim
    if !s:term_support
      call term_sendkeys(a:bufnr, "\<C-u>\<C-k>".a:value)
    endif
    " call timer_start(3000, { -> term_sendkeys(bufnr, "\<C-u>\<C-k>abcd")})
  else
    let mode = mode()
    if mode ==# 'i'
      call feedkeys("\<end>", 'int')
    else
      call feedkeys("\<esc>A", 'int')
    endif
    " Use complete to replace text before
    let saved_completeopt = &completeopt
    if saved_completeopt =~ 'menuone'
      noa set completeopt=menu
    endif
    noa call complete(1, [{ 'empty': 1, 'word': a:value }])
    call feedkeys("\<C-x>\<C-z>", 'in')
    execute 'noa set completeopt='.saved_completeopt
  endif
endfunction

function! coc#dialog#change_loading(winid, loading) abort
  if coc#float#valid(a:winid)
    let winid = coc#float#get_related(a:winid, 'loading')
    if !a:loading && winid > 0
      call coc#float#close(winid)
    endif
    if a:loading && winid == 0
      let bufnr = s:create_loading_buf()
      if s:is_vim
        let pos = popup_getpos(a:winid)
        let winid = popup_create(bufnr, {
            \ 'line': pos['line'] + 1,
            \ 'col': pos['col'] + pos['width'] - 4,
            \ 'maxheight': 1,
            \ 'maxwidth': 3,
            \ 'zindex': 999,
            \ 'highlight': get(popup_getoptions(a:winid), 'highlight', 'CocFloating')
            \ })
      else
        let pos = nvim_win_get_position(a:winid)
        let width = nvim_win_get_width(a:winid)
        let opts = {
            \ 'relative': 'editor',
            \ 'row': pos[0],
            \ 'col': pos[1] + width - 3,
            \ 'focusable': v:false,
            \ 'width': 3,
            \ 'height': 1,
            \ 'style': 'minimal',
            \ 'zindex': 900,
            \ }
        let winid = nvim_open_win(bufnr, v:false, opts)
        call setwinvar(winid, '&winhl', getwinvar(a:winid, '&winhl'))
      endif
      call setwinvar(winid, 'kind', 'loading')
      call setbufvar(bufnr, 'target_winid', a:winid)
      call setbufvar(bufnr, 'popup', winid)
      call coc#float#add_related(winid, a:winid)
    endif
  endif
endfunction

" Update list with new lines and highlights
function! coc#dialog#update_list(winid, bufnr, lines, highlights) abort
  if coc#window#tabnr(a:winid) == tabpagenr()
    if getwinvar(a:winid, 'auto_height', 0)
      let row = coc#float#get_row(a:winid)
      let width = getwinvar(a:winid, 'core_width', 80)
      let height = s:get_height(a:lines, width)
      let height = min([getwinvar(a:winid, 'max_height', 10), height, &lines - &cmdheight - 1 - row])
      let curr = s:is_vim ? popup_getpos(a:winid)['core_height'] : nvim_win_get_height(a:winid)
      let delta = height - curr
      if delta != 0
        call coc#float#change_height(a:winid, delta)
      endif
    endif
    call coc#compat#buf_set_lines(a:bufnr, 0, -1, a:lines)
    call coc#highlight#add_highlights(a:winid, [], a:highlights)
    if s:is_vim
      let target = getwinvar(a:winid, 'target_winid', -1)
      if target != -1
        call coc#dialog#check_scroll_vim(target)
      endif
      call win_execute(a:winid, 'exe 1')
    endif
  endif
endfunction

" Fix width of prompt window same as list window on scrollbar change
function! coc#dialog#check_scroll_vim(winid) abort
  if s:is_vim && coc#float#valid(a:winid)
    let winid = coc#float#get_related(a:winid, 'list')
    if winid
      redraw
      let pos = popup_getpos(winid)
      let width = pos['width'] + (pos['scrollbar'] ? 1 : 0)
      if width != popup_getpos(a:winid)['width']
        call popup_move(a:winid, {
            \ 'minwidth': width - 2,
            \ 'maxwidth': width - 2,
            \ })
      endif
    endif
  endif
endfunction

function! coc#dialog#set_cursor(winid, bufnr, line) abort
  if a:winid >= 0
    if s:is_vim
      call win_execute(a:winid, 'exe ' . max([a:line, 1]), 'silent!')
      call popup_setoptions(a:winid, {'cursorline' : 1})
      call popup_setoptions(a:winid, {'cursorline' : 0})
    else
      call nvim_win_set_cursor(a:winid, [max([a:line, 1]), 0])
    endif
    call coc#dialog#place_sign(a:bufnr, a:line)
  endif
endfunction

function! coc#dialog#place_sign(bufnr, line) abort
  call sign_unplace(s:sign_group, { 'buffer': a:bufnr })
  if a:line > 0
    call sign_place(6, s:sign_group, 'CocCurrentLine', a:bufnr, {'lnum': a:line})
  endif
endfunction

function! s:create_prompt_win(bufnr, title, default, opts) abort
  let config = s:get_prompt_dimension(a:title, a:default, a:opts)
  return coc#float#create_float_win(0, a:bufnr, extend(config, {
        \ 'style': 'minimal',
        \ 'border': get(a:opts, 'border', [1,1,1,1]),
        \ 'rounded': get(a:opts, 'rounded', 1),
        \ 'prompt': 1,
        \ 'title': a:title,
        \ 'lines': s:is_vim ? v:null : [a:default],
        \ 'highlight': get(a:opts, 'highlight', 'CocFloating'),
        \ 'borderhighlight': [get(a:opts, 'borderhighlight', 'CocFloatBorder')],
        \ }))
endfunction

" Could be center(with optional marginTop) or cursor
function! s:get_prompt_dimension(title, default, opts) abort
  let relative = get(a:opts, 'position', 'cursor') ==# 'cursor' ? 'cursor' : 'editor'
  let curr = win_screenpos(winnr())[1] + wincol() - 2
  let minWidth = get(a:opts, 'minWidth', s:prompt_win_width)
  let width = min([max([strwidth(a:default) + 2, strwidth(a:title) + 2, minWidth]), &columns - 2])
  if get(a:opts, 'maxWidth', 0)
    let width = min([width, a:opts['maxWidth']])
  endif
  if relative ==# 'cursor'
    let [lineIdx, colIdx] = coc#cursor#screen_pos()
    if width == &columns - 2
      let col = 0 - curr
    else
      let col = curr + width <= &columns - 2 ? 0 : curr + width - &columns + 2
    endif
    let config = {
        \ 'row': lineIdx == 0 ? 1 : 0,
        \ 'col': colIdx == 0 ? 0 : col - 1,
        \ }
  else
    let marginTop = get(a:opts, 'marginTop', v:null)
    if marginTop is v:null
      let row = (&lines - &cmdheight - 2) / 2
    else
      let row = marginTop < 2 ? 1 : min([marginTop, &columns - &cmdheight])
    endif
    let config = {
          \ 'col': float2nr((&columns - width) / 2),
          \ 'row': row - s:is_vim,
          \ }
  endif
  return extend(config, {'relative': relative, 'width': width, 'height': 1})
endfunction

function! s:min_btns_width(buttons) abort
  if empty(a:buttons)
    return 0
  endif
  let minwidth = len(a:buttons)*3 - 1
  for txt in a:buttons
    let minwidth = minwidth + strdisplaywidth(txt)
  endfor
  return minwidth
endfunction

" Close windows that should auto hide
function! s:close_auto_hide_wins(...) abort
  let winids = coc#float#get_float_win_list()
  let except = get(a:, 1, 0)
  for id in winids
    if except && id == except
      continue
    endif
    if getwinvar(id, 'autohide', 0)
      call coc#float#close(id)
    endif
  endfor
endfunction

function! s:create_loading_buf() abort
  let bufnr = coc#float#create_buf(0)
  call s:change_loading_buf(bufnr, 0)
  return bufnr
endfunction

function! s:get_height(lines, width) abort
  let height = 0
  for line in a:lines
    let height += float2nr(strdisplaywidth(line) / a:width) + 1
  endfor
  return max([1, height])
endfunction

function! s:change_loading_buf(bufnr, idx) abort
  if bufloaded(a:bufnr)
    let target = getbufvar(a:bufnr, 'target_winid', v:null)
    if !empty(target) && !coc#float#valid(target)
      call coc#float#close(getbufvar(a:bufnr, 'popup'))
      return
    endif
    let line = get(s:frames, a:idx, '   ')
    call setbufline(a:bufnr, 1, line)
    call coc#highlight#add_highlight(a:bufnr, -1, 'CocNotificationProgress', 0, 0, -1)
    let idx = a:idx == len(s:frames) - 1 ? 0 : a:idx + 1
    call timer_start(100, { -> s:change_loading_buf(a:bufnr, idx)})
  endif
endfunction

function! s:on_quickpick_selected(errMsg, res) abort
  if !empty(a:errMsg)
    throw a:errMsg
  endif
  call timer_start(50, { -> coc#rpc#notify('InputListSelect', [a:res - 1])})
endfunction
