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

" Return the word under the cursor, uses spaces to delimitate
" Modified GetCurrentWord() from http://www.vim.org/scripts/script.php?script_id=143
function! s:Toggle_getCurrentWord(colNo, lineNo)
  let l = getline(a:lineNo)
  let l1 = strpart(l, 0, a:colNo)
  let l1 = matchstr(l1, '\S*$')

  if strlen(l1) == 0
    return l1
  else
    let l2 = strpart(l, a:colNo, strlen(l) - a:colNo + 1)
    let l2 = strpart(l2, 0, match(l2, '$\|\s'))
    return l1 . l2
  endif
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
  let s:wordUnderCursor = s:Toggle_getCurrentWord(s:columnNo, s:lineNo)
  let s:wordUnderCursor_tmp = ''

  " 1. Arithmetic and relational operators {{{2
  function! s:HandleMath(x, y)
    if s:toggleDone
      return
    endif

    if s:charUnderCursor == a:x
      execute "normal r" . a:y
      let s:toggleDone = 1
    elseif s:charUnderCursor == a:y
      execute "normal r" . a:x
      let s:toggleDone = 1
    endif
  endfunction

  function! s:DoMaths()
    call s:HandleMath("+", "-")
    call s:HandleMath("<", ">")
  endfunction
  " }}}2

  " 2. Numbers {{{2
  function! s:HandleNumber(arg)
    if s:toggleDone
      return
    endif

    call setline(s:lineNo, a:arg)
    let s:toggleDone = 1
  endfunction

  function! s:DoNumbers()
    if s:charUnderCursor =~ "\\d" " is a digit (number)
      let s:col_tmp = s:columnNo - 1
      let s:foundSpace = 0
      let s:spacePos = -1

      while s:col_tmp >= 0 && ! s:toggleDone
        let s:cuc = strpart(s:cline, s:col_tmp, 1)

        if s:cuc == "+"
          call s:HandleNumber(s:Toggle_changeChar(s:cline, s:col_tmp, "-"))
        elseif s:cuc == "-"
          call s:HandleNumber(s:Toggle_changeChar(s:cline, s:col_tmp, "+"))
        elseif s:cuc == " "
          let s:foundSpace = 1
          " Set spacePos so sign is directly before number if there are several spaces
          if (s:spacePos == -1)
            let s:spacePos = s:col_tmp
          endif
        elseif s:cuc !~ "\\s" && s:foundSpace == 1
          " If any non-space character precedes `foundSpace`, insert `-` and keep a space
          call s:HandleNumber(s:Toggle_changeChar(s:cline, s:spacePos, " -"))
        elseif s:cuc !~ "\\d" && s:cuc !~ "\\s"
          " If preceded by any non-digit or non-space character, insert `-`
          call s:HandleNumber(s:Toggle_insertChar(s:cline, s:col_tmp + 1, "-"))
        endif

        let s:col_tmp = s:col_tmp - 1
      endwhile

      if ! s:toggleDone
        " No sign found, insert `-` at beginning of line
        call s:HandleNumber("-" . s:cline)
      endif
    endif
  endfunction
  " }}}2

  " 3. Logical and binary operators {{{2
  function! s:HandleOperator(x, y)
    if s:toggleDone
      return
    endif

    if s:charUnderCursor == a:x
      if s:prevChar == a:x
        execute "normal r" . a:y . "hr" . a:y
      elseif s:nextChar == a:x
        execute "normal r" . a:y . "lr" . a:y
      else
        execute "normal r" . a:y
      endif
      let s:toggleDone = 1
    endif
  endfunction

  function! s:DoOperators()
    call s:HandleOperator("|", "&")
    call s:HandleOperator("&", "|")
  endfunction
  " }}}2

  " 4. Strings {{{2
  function! s:HandleString(x, y)
    if s:toggleDone
      return
    endif

    if s:wordUnderCursor ==? a:x
      let s:wordUnderCursor_tmp = a:y
      let s:toggleDone = 1
    elseif s:wordUnderCursor ==? a:y
      let s:wordUnderCursor_tmp = a:x
      let s:toggleDone = 1
    endif
  endfunction

  function! s:DoStrings()
    call s:HandleString("true", "false")
    call s:HandleString("on", "off")
    call s:HandleString("yes", "no")
    call s:HandleString("define", "undef")

    if s:toggleDone
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
    endif
  endfunction
  " }}}2

  " 5. Not found {{{2
  function! s:NotFound()
    echohl WarningMsg
    echo "Can't toggle word under cursor, word is not in list."
    echohl None
  endfunction
  " }}}2

  if ! s:toggleDone
    call s:DoMaths()
  endif

  if ! s:toggleDone
    call s:DoNumbers()
  endif

  if ! s:toggleDone
    call s:DoOperators()
  endif

  if ! s:toggleDone
    call s:DoStrings()
  endif

  if ! s:toggleDone
    call s:NotFound()
  endif

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
