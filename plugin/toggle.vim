" toggle.vim
" Maintainer: Ryan Todd Garza <https://ryantoddgarza.com/>
" Version: 0.7

if exists("g:loaded_toggle")
  finish
endif
let g:loaded_toggle = 1

let s:save_cpo = &cpo
set cpo&vim

" Helper functions {{{1

function! s:Toggle_changeChar(string, pos, char)
  return strpart(a:string, 0, a:pos) . a:char . strpart(a:string, a:pos + 1)
endfunction

function! s:Toggle_insertChar(string, pos, char)
  return strpart(a:string, 0, a:pos) . a:char . strpart(a:string, a:pos)
endfunction

" }}}1

" Toggle function {{{1
function! s:Toggle()
  let s:toggleDone = 0
  let s:columnNo = col(".")
  let s:lineNo = line(".")
  let s:cline = getline(s:lineNo)
  let s:charUnderCursor = strpart(s:cline, s:columnNo - 1, 1)
  let s:nextChar = strpart(s:cline, s:columnNo, 1)
  let s:prevChar = strpart(s:cline, s:columnNo - 2, 1)
  let s:wordUnderCursor = expand('<cword>')
  let s:wordUnderCursor_tmp = ''

  " 1. Arithmetic, inc/dec, relational, logical, and bitwise operators {{{2
  function! HandleOperator(x, y)
    if s:charUnderCursor == a:x || s:charUnderCursor == a:y
      if s:prevChar == a:x
        execute "normal r" . a:y . "hr" . a:y
      elseif s:nextChar == a:x
        execute "normal r" . a:y . "lr" . a:y
      elseif s:prevChar == a:y
        execute "normal r" . a:x . "hr" . a:x
      elseif s:nextChar == a:y
        execute "normal r" . a:x . "lr" . a:x
      elseif s:charUnderCursor == a:x
        execute "normal r" . a:y
      elseif s:charUnderCursor == a:y
        execute "normal r" . a:x
      endif
      let s:toggleDone = 1
    endif
  endfunction
  " }}}2

  " 2. Numbers {{{2
  function! SetLineAndDone(arg)
    call setline(s:lineNo, a:arg)
    let s:toggleDone = 1
  endfunction

  function! HandleNumbers()
    if s:charUnderCursor =~ "\\d" " is a digit (number)
      let s:col_tmp = s:columnNo - 1
      let s:foundSpace = 0
      let s:spacePos = -1

      while s:col_tmp >= 0 && ! s:toggleDone
        let s:cuc = strpart(s:cline, s:col_tmp, 1)

        if s:cuc == "+"
          call SetLineAndDone(s:Toggle_changeChar(s:cline, s:col_tmp, "-"))
        elseif s:cuc == "-"
          call SetLineAndDone(s:Toggle_changeChar(s:cline, s:col_tmp, "+"))
        elseif s:cuc == " "
          let s:foundSpace = 1
          " Set spacePos so sign is directly before number if there are several spaces
          if (s:spacePos == -1)
            let s:spacePos = s:col_tmp
          endif
        elseif s:cuc !~ "\\s" && s:foundSpace == 1
          " If any non-space character precedes `foundSpace`, insert `-` and keep a space
          call SetLineAndDone(s:Toggle_changeChar(s:cline, s:spacePos, " -"))
        elseif s:cuc !~ "\\d" && s:cuc !~ "\\s"
          " If preceded by any non-digit or non-space character, insert `-`
          call SetLineAndDone(s:Toggle_insertChar(s:cline, s:col_tmp + 1, "-"))
        endif

        let s:col_tmp = s:col_tmp - 1
      endwhile

      if ! s:toggleDone
        " No sign found, insert `-` at beginning of line
        call SetLineAndDone("-" . s:cline)
      endif
    endif
  endfunction
  " }}}2

  " 3. Strings {{{2
  function! PreserveCase()
    " Preserve case (provided by Jan Christoph Ebersbach)
    if strpart(s:wordUnderCursor, 0) =~ '^\u*$'
      let s:wordUnderCursor = toupper(s:wordUnderCursor_tmp)
    elseif strpart(s:wordUnderCursor, 0, 1) =~ '^\u$'
      let s:wordUnderCursor = toupper(strpart(s:wordUnderCursor_tmp, 0, 1)) . strpart(s:wordUnderCursor_tmp, 1)
    else
      let s:wordUnderCursor = s:wordUnderCursor_tmp
    endif

    " Set the new line
    execute "normal ciw" . s:wordUnderCursor
  endfunction

  function! HandleString(x, y)
    if s:wordUnderCursor ==? a:x
      let s:wordUnderCursor_tmp = a:y
      call PreserveCase()
      let s:toggleDone = 1
    elseif s:wordUnderCursor ==? a:y
      let s:wordUnderCursor_tmp = a:x
      call PreserveCase()
      let s:toggleDone = 1
    endif
  endfunction
  " }}}2

  " 4. Not found {{{2
  function! NotFound()
    echohl WarningMsg
    echo "Can't toggle word under cursor, word is not in list."
    echohl None
  endfunction
  " }}}2

  " Iterate function {{{2
  let fnList = [
        \ function("HandleOperator", ["+", "-"]),
        \ function("HandleOperator", ["<", ">"]),
        \ function("HandleOperator", ["&", "|"]),
        \ function("HandleNumbers"),
        \ function("HandleString", ["true", "false"]),
        \ function("HandleString", ["on", "off"]),
        \ function("HandleString", ["yes", "no"]),
        \ function("HandleString", ["define", "undef"]),
        \ function("NotFound"),
        \ ]

  function! FnListIter(list) abort
    for Fn in a:list
      if s:toggleDone
        return
      endif

      call Fn()
    endfor
  endfunction
  " }}}2

  call FnListIter(fnList)

  " Restore saved values
  call cursor(s:lineNo, s:columnNo)
endfunction
" }}}1

" Mapping {{{1

inoremap <silent> <Plug>ToggleI <C-O>:call <SID>Toggle()<CR>
nnoremap <silent> <Plug>ToggleN :<C-U>call <SID>Toggle()<CR>
vnoremap <silent> <Plug>ToggleV <ESC>:call <SID>Toggle()<CR>

if !hasmapto('<Plug>ToggleI', 'i')
  imap <C-T> <Plug>ToggleI
endif

if !hasmapto('<Plug>ToggleN', 'n')
  nmap + <Plug>ToggleN
endif

if !hasmapto('<Plug>ToggleV', 'v')
  vmap + <Plug>ToggleV
endif

" }}}1

let &cpo = s:save_cpo
unlet s:save_cpo
