" Initialize -------------------------------------------------------------------
let s:plugin_name = "quick-scope"

if exists('g:loaded_quick_scope')
  finish
endif

let g:loaded_quick_scope = 1

if &compatible
  echoerr s:plugin_name . " won't load in Vi-compatible mode."
  finish
endif

" @todo: Actually test which versions of Vim this plugin supports.
if v:version < 700
  echoerr s:plugin_name . " requires Vim running in version 7 or later."
  finish
endif

unlet! s:plugin_name

" Save cpoptions and reassign them later. See :h use-cpo-save.
let s:cpo_save = &cpo
set cpo&vim

" Options " -------------------------------------------------------------------
if !exists('g:qs_enable')
  let g:qs_enable = 1
endif

if exists('g:qs_highlight_on_key_press') && g:qs_highlight_on_key_press == 1
  noremap <unique> <expr> <silent> f <sid>find('f') . <sid>find_cleanup()
  noremap <unique> <expr> <silent> F <sid>find('F') . <sid>find_cleanup()
  noremap <unique> <expr> <silent> t <sid>find('t') . <sid>find_cleanup()
  noremap <unique> <expr> <silent> T <sid>find('T') . <sid>find_cleanup()
else
  augroup quick_scope
    autocmd!
    autocmd CursorMoved,InsertLeave,ColorScheme * call s:unhighlight_line() | call s:highlight_line()
    autocmd InsertEnter * call s:unhighlight_line()
    " autocmd VimEnter,ColorScheme * call s:set_highlight_colors()
  augroup END
endif

let s:chars_s = []

function! s:custom()
  let s:ccount = s:ccount + 1
  if s:ccount == 2
    call s:unhighlight_line()
    call s:add_to_highlight_group(s:hi_group_secondary, 'fg', s:secondary_color)
    autocmd! quick_scope CursorMoved
  endif
endfunction

function! s:find(motion)
  " reset
  call s:add_to_highlight_group(s:hi_group_secondary, 'fg', s:secondary_color)
  call s:unhighlight_line()
  autocmd! quick_scope CursorMoved

  if (a:motion ==# 'f' || a:motion ==# 't')
    let s:direction = 1
  else
    let s:direction = 0
  endif

  call s:highlight_line(s:direction, '')

  " Keep the cursor visible in the editor.
  let s:cursor = matchadd(s:hi_group_cursor, '\%#', s:priority + 1)

  redraw

  let s:save = {'t_ve': &t_ve , 'guicursor': &guicursor}

  " Hide the cursor on the command line.
  set t_ve=
  set guicursor=n:block-NONE

  " Store the target for the character motion.
  let s:char = nr2char(getchar())

  return a:motion . s:char
endfunction

function! s:find_cleanup()
  call matchdelete(s:cursor)

  " Restore the cursor on the command line.
  set guicursor&
  let &guicursor = s:save['guicursor']
  let &t_ve = s:save['t_ve']

  call s:unhighlight_line()

  if index(s:chars_s, s:char) != -1
    call s:highlight_line(s:direction, s:char)
    for m in filter(getmatches(), printf('v:val.group ==# "%s"', s:hi_group_primary))
      call matchdelete(m.id)
    endfor

    call s:add_to_highlight_group(s:hi_group_secondary, 'fg', s:primary_color)
    "
    let s:ccount = 0

    augroup quick_scope
      autocmd CursorMoved * call s:custom()
    augroup END
  endif

  let s:chars_s = []

  " Intentionally return an empty string.
  return ''
endfunction

" User commands ---------------------------------------------------------------
function! s:toggle()
  if g:qs_enable
    let g:qs_enable = 0
    call <sid>unhighlight_line()
  else
    let g:qs_enable = 1
    call <sid>highlight_line()
  endif
endfunction

command! -nargs=0 QuickScopeToggle call s:toggle()

" Plug mappings ---------------------------------------------------------------
nnoremap <silent> <plug>(QuickScopeToggle) :call <sid>toggle()<cr>
vnoremap <silent> <plug>(QuickScopeToggle) :<c-u>call <sid>toggle()<cr>

" Autoload --------------------------------------------------------------------
augroup quick_scope
  " autocmd!
  autocmd VimEnter,ColorScheme * call s:set_highlight_colors()
augroup END

" Colors ----------------------------------------------------------------------
" Priority for overruling other highlight matches.
let s:priority = 1

" Highlight group marking first appearance of characters in a line.
let s:hi_group_primary = 'QuickScopePrimary'
let s:hi_group_secondary = 'QuickScopeSecondary'

" Highlight group marking temproary cursor when quick-scope is enabled on key
" press.
let s:hi_group_cursor = 'QuickScopeCursor'

" Detect if the running instance of Vim acts as a GUI or terminal.
function! s:get_term()
  if has('gui_running') || (has('nvim') && $NVIM_TUI_ENABLE_TRUE_COLOR)
    let term = 'gui'
  else
    let term ='cterm'
  endif

  return term
endfunction

" Called when no color configurations are set. Choose default colors for
" highlighting.
function! s:set_default_color(group, co_gui, co_256, co_16)
  let term = s:get_term()

  " Pick a color from an existing highlight group if the highlight group
  " exists.
  if hlexists(a:group)
    let color = synIDattr(synIDtrans(hlID(a:group)), 'fg', term)
  endif

  if color == -1
    if term ==# 'gui'
      let color = a:co_gui
    else
      if &t_Co > 255
        let color = a:co_256
      else
        let color = a:co_16
      endif
    endif
  endif

  return color
endfunction

" Set or append to a custom highlight group.
function! s:add_to_highlight_group(group, attr, color)
  execute printf("highlight %s %s%s=%s", a:group, s:get_term(), a:attr, a:color)
endfunction

" Set the colors used for highlighting.
function! s:set_highlight_colors()
  if !exists('g:qs_first_occurrence_highlight_color')
    " set color to match 'Function' highlight group or bright green
    let g:qs_first_occurrence_highlight_color = s:set_default_color('Function', '#afff5f', 155, 10)
    let s:primary_color = g:qs_first_occurrence_highlight_color
  endif

  if !exists('g:qs_second_occurrence_highlight_color')
    " set color to match 'Keyword' highlight group or cyan
    let g:qs_second_occurrence_highlight_color = s:set_default_color('Define', '#5fffff', 81, 14)
    let s:secondary_color = g:qs_second_occurrence_highlight_color
  endif

  call s:add_to_highlight_group(s:hi_group_primary, '', 'underline')
  call s:add_to_highlight_group(s:hi_group_primary, 'fg', g:qs_first_occurrence_highlight_color)
  call s:add_to_highlight_group(s:hi_group_secondary, '', 'underline')
  call s:add_to_highlight_group(s:hi_group_secondary, 'fg', g:qs_second_occurrence_highlight_color)

  " Cursor
  execute printf("highlight link %s Cursor", s:hi_group_cursor)

  " Preserve the background color of cursorline if it exists.
  if &cursorline
    let bg_color = synIDattr(synIDtrans(hlID('CursorLine')), 'bg', s:get_term())

    if bg_color != -1
      call s:add_to_highlight_group(s:hi_group_primary, 'bg', bg_color)
      call s:add_to_highlight_group(s:hi_group_secondary, 'bg', bg_color)
    endif
  endif
endfunction

" Primary functions -----------------------------------------------------------
" Apply the highlights for each highlight group based on pattern strings.
"
" Arguments are expected to be lists of two items.
function! s:apply_highlight_patterns(patterns)
  let [patt_p, patt_s] = a:patterns
  if !empty(patt_p)
    " Highlight columns corresponding to matched characters.
    "
    " Ignore the leading | in the primary highlights string.
    call matchadd(s:hi_group_primary, '\v%' . line('.') . 'l(' . patt_p[1:] . ')', s:priority)
  endif
  if !empty(patt_s)
    call matchadd(s:hi_group_secondary, '\v%' . line('.') . 'l(' . patt_s[1:] . ')', s:priority)
  endif
endfunction

function! s:get_chars_with_secondary_highlights(chars)
  let [char_p, char_s] = a:chars

  " @todo: empty vs equality for empty string
  if char_p != ''
  elseif char_s != ''
    call add(s:chars_s, char_s)
  endif
endfunction

" Set or append to the pattern strings for the highlights.
function! s:add_to_highlight_patterns(patterns, highlights)
  let [patt_p, patt_s] = a:patterns
  let [hi_p, hi_s] = a:highlights

  " If there is a primary highlight for the last word, add it to
  " the primary highlight pattern.
  if hi_p > 0
    let patt_p = printf("%s|%%%sc", patt_p, hi_p)
  elseif hi_s > 0
    let patt_s = printf("%s|%%%sc", patt_s, hi_s)
  endif

  return [patt_p, patt_s]
endfunction

" Finds which characters to highlight and returns their column positions as a
" pattern string.
function! s:get_highlight_patterns(line, start, end, target)
  " Patterns to match the characters that will be marked with primary and
  " secondary highlight groups, respectively
  let [patt_p, patt_s] = ['', '']

  " Keys correspond to characters that can be highlighted. Values refer to
  " occurrences of each character on a line.
  if a:target == ''
    let accepted_chars = {'a': 0, 'b': 0, 'c': 0, 'd': 0, 'e': 0, 'f': 0, 'g': 0, 'h': 0, 'i': 0, 'j': 0, 'k': 0, 'l': 0, 'm': 0, 'n': 0, 'o': 0, 'p': 0, 'q': 0, 'r': 0, 's': 0, 't': 0, 'u': 0, 'v': 0, 'w': 0, 'x': 0, 'y': 0, 'z': 0, 'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0, 'F': 0, 'G': 0, 'H': 0, 'I': 0, 'J': 0, 'K': 0, 'L': 0, 'M': 0, 'N': 0, 'O': 0, 'P': 0, 'Q': 0, 'R': 0, 'S': 0, 'T': 0, 'U': 0, 'V': 0, 'W': 0, 'X': 0, 'Y': 0, 'Z': 0, '0': 0, '1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0,}
  else
    let accepted_chars = {}
    let accepted_chars[a:target] = 0
  endif

  " Indicates whether this is the first word under the cursor. We don't want
  " to highlight any characters in it.
  let is_first_word = 1

  " The position of a character in a word that will be given a highlight. A
  " value of 0 indicates there is no character to highlight.
  let [hi_p, hi_s] = [0, 0]
  let [char_p, char_s] = ['', '']

  " If 1, we're looping forwards from the cursor to the end of the line;
  " otherwise, we're looping from the cursor to the beginning of the line.
  let direction = a:start < a:end ? 1 : 0

  let i = a:start
  while i != a:end
    let char = a:line[i]

    " Don't consider the character for highlighting, but mark the position
    " as the start of a new word.
    "
    " Check for a <space> as a first condition for optimization.
    if char == "\<space>" || !has_key(accepted_chars, char) || empty(char)
      if !is_first_word
        let [patt_p, patt_s] = s:add_to_highlight_patterns([patt_p, patt_s], [hi_p, hi_s])
        call s:get_chars_with_secondary_highlights([char_p, char_s])
      endif

      " We've reached a new word, so reset any highlights.
      let [hi_p, hi_s] = [0, 0]
      let [char_p, char_s] = ['', '']

      let is_first_word = 0
    else
      let accepted_chars[char] += 1

      if !is_first_word
        let occurrences = get(accepted_chars, char)

        " If the search is forward, we want to be greedy; otherwise, we
        " want to be reluctant. This prioritizes highlighting for
        " characters at the beginning of a word.
        "
        " If this is the first occurence of the letter in the word,
        " mark it for a highlight.
        if occurrences == 1 && ((direction == 1 && hi_p == 0) || direction == 0)
          let hi_p = i + 1
          let char_p = char
        elseif occurrences == 2 && ((direction == 1 && hi_s == 0) || direction == 0)
          let hi_s = i + 1
          let char_s = char
        endif
      endif
    endif

    if direction == 1
      let i += 1
    else
      let i -= 1
    endif
  endwhile

  let [patt_p, patt_s] = s:add_to_highlight_patterns([patt_p, patt_s], [hi_p, hi_s])
  call s:get_chars_with_secondary_highlights([char_p, char_s])

  return [patt_p, patt_s]
endfunction

" Can take an optional direction: 0 (backward) or 1 (forward)
function! s:highlight_line(dir, target)
  if g:qs_enable
    let line = getline(line('.'))
    let len = strlen(line)
    let pos = col('.')

    let target = a:target

    if !empty(line)
      if a:dir != 0
        " Highlights after the cursor.
        let [patt_p, patt_s] = s:get_highlight_patterns(line, pos, len, target)
        call s:apply_highlight_patterns([patt_p, patt_s])
      endif

      if a:dir != 1
        let pos -= 2
        if pos < 0 | let pos = 0 | endif

        " Highlights before the cursor.
        let [patt_p, patt_s] = s:get_highlight_patterns(line, pos, -1, target)
        call s:apply_highlight_patterns([patt_p, patt_s])
      endif
    endif
  endif
endfunction

function! s:unhighlight_line()
  for m in filter(getmatches(), printf('v:val.group ==# "%s" || v:val.group ==# "%s"', s:hi_group_primary, s:hi_group_secondary))
    call matchdelete(m.id)
  endfor
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
