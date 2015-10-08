" Initialize -----------------------------------------------------------------
let s:plugin_name = "quick-scope"

if exists('g:loaded_quick_scope')
  finish
endif

let g:loaded_quick_scope = 1

if &compatible
  echoerr s:plugin_name . " won't load in Vi-compatible mode."
  finish
endif

if v:version < 701 || (v:version == 701 && !has('patch040'))
  echoerr s:plugin_name . " requires Vim running in version 7.1.040 or later."
  finish
endif

unlet! s:plugin_name

" Save cpoptions and reassign them later. See :h use-cpo-save.
let s:cpo_save = &cpo
set cpo&vim

" Autocommands ---------------------------------------------------------------
augroup quick_scope
  autocmd!
  autocmd ColorScheme * call s:set_highlight_colors()
augroup END

" Options --------------------------------------------------------------------
if !exists('g:qs_enable')
  let g:qs_enable = 1
endif

" Change this to an option for a future update...
if !exists('s:accepted_chars')
  " Keys correspond to characters that can be highlighted. Values aren't used.
  let s:accepted_chars = {'a': 0, 'b': 0, 'c': 0, 'd': 0, 'e': 0, 'f': 0, 'g': 0, 'h': 0, 'i': 0, 'j': 0, 'k': 0, 'l': 0, 'm': 0, 'n': 0, 'o': 0, 'p': 0, 'q': 0, 'r': 0, 's': 0, 't': 0, 'u': 0, 'v': 0, 'w': 0, 'x': 0, 'y': 0, 'z': 0, 'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0, 'F': 0, 'G': 0, 'H': 0, 'I': 0, 'J': 0, 'K': 0, 'L': 0, 'M': 0, 'N': 0, 'O': 0, 'P': 0, 'Q': 0, 'R': 0, 'S': 0, 'T': 0, 'U': 0, 'V': 0, 'W': 0, 'X': 0, 'Y': 0, 'Z': 0, '0': 0, '1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0,}
endif

if !exists('g:qs_highlight_on_keys')
  " Vanilla mode. Highlight on cursor movement.
  augroup quick_scope
    autocmd CursorMoved,InsertLeave,ColorScheme * call s:unhighlight_line() | call s:highlight_line(2, s:accepted_chars)
    autocmd InsertEnter * call s:unhighlight_line()
  augroup END
else
  " Highlight on key press. Set an 'augmented' mapping for each defined key.
  for motion in filter(g:qs_highlight_on_keys, 'v:val =~# "^[fFtT]$"')
    execute printf('noremap <unique> <silent> <expr> %s <sid>ready() . <sid>aim("%s") . <sid>reload() . <sid>double_tap()', motion, motion)
  endfor
endif

" User commands --------------------------------------------------------------
function! s:toggle()
  if g:qs_enable
    let g:qs_enable = 0
    call <sid>unhighlight_line()
  else
    let g:qs_enable = 1
    doautocmd CursorMoved
  endif
endfunction

command! -nargs=0 QuickScopeToggle call s:toggle()

" Plug mappings --------------------------------------------------------------
nnoremap <silent> <plug>(QuickScopeToggle) :call <sid>toggle()<cr>
vnoremap <silent> <plug>(QuickScopeToggle) :<c-u>call <sid>toggle()<cr>

" Colors ---------------------------------------------------------------------
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

  if !exists('color')
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
  " Priority for overruling other highlight matches.
  let s:priority = 1

  " Highlight group marking first appearance of characters in a line.
  let s:hi_group_primary = 'QuickScopePrimary'
  let s:hi_group_secondary = 'QuickScopeSecondary'

  " Highlight group marking dummy cursor when quick-scope is enabled on key
  " press.
  let s:hi_group_cursor = 'QuickScopeCursor'

  if !exists('g:qs_first_occurrence_highlight_color')
    " set color to match 'Function' highlight group or lime green
    let s:primary_highlight_color = s:set_default_color('Function', '#afff5f', 155, 10)
  else
    let s:primary_highlight_color = g:qs_first_occurrence_highlight_color
  endif

  if !exists('g:qs_second_occurrence_highlight_color')
    " set color to match 'Keyword' highlight group or cyan
    let s:secondary_highlight_color = s:set_default_color('Define', '#5fffff', 81, 14)
  else
    let s:secondary_highlight_color = g:qs_second_occurrence_highlight_color
  endif

  call s:add_to_highlight_group(s:hi_group_primary, '', 'underline')
  call s:add_to_highlight_group(s:hi_group_primary, 'fg', s:primary_highlight_color)
  call s:add_to_highlight_group(s:hi_group_secondary, '', 'underline')
  call s:add_to_highlight_group(s:hi_group_secondary, 'fg', s:secondary_highlight_color)
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

call s:set_highlight_colors()

" Main highlighting functions ------------------------------------------------
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

" Keep track of which characters have a secondary highlight (but no primary
" highlight) and store them in :chars_s. Used when g:qs_highlight_on_keys is
" active to decide whether to trigger an extra highlight.
function! s:save_chars_with_secondary_highlights(chars)
  let [char_p, char_s] = a:chars

  if !empty(char_p)
    " Do nothing
  elseif !empty(char_s)
    call add(s:chars_s, char_s)
  endif
endfunction

" Set or append to the pattern strings for the highlights.
function! s:add_to_highlight_patterns(patterns, highlights)
  let [patt_p, patt_s] = a:patterns
  let [hi_p, hi_s] = a:highlights

  " If there is a primary highlight for the last word, add it to the primary
  " highlight pattern.
  if hi_p > 0
    let patt_p = printf("%s|%%%sc", patt_p, hi_p)
  elseif hi_s > 0
    let patt_s = printf("%s|%%%sc", patt_s, hi_s)
  endif

  return [patt_p, patt_s]
endfunction

" Finds which characters to highlight and returns their column positions as a
" pattern string.
function! s:get_highlight_patterns(line, start, end, targets)
  " Keeps track of the number of occurrences for each target
  let occurrences = {}

  " Patterns to match the characters that will be marked with primary and
  " secondary highlight groups, respectively
  let [patt_p, patt_s] = ['', '']

  " Indicates whether this is the first word under the cursor. We don't want
  " to highlight any characters in it.
  let is_first_word = 1

  " The positions of the (next) characters that will be given a highlight. A
  " value of 0 indicates there is no character to highlight.
  let [hi_p, hi_s] = [0, 0]

  " The (next) characters that will be given a highlight. Used by
  " save_chars_with_secondary_highlights() to see whether an extra highlight
  " should be triggered if g:qs_highlight_on_keys is active.
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
    if char == "\<space>" || !has_key(a:targets, char) || empty(char)
      if !is_first_word
        let [patt_p, patt_s] = s:add_to_highlight_patterns([patt_p, patt_s], [hi_p, hi_s])

        if exists('g:qs_highlight_on_keys')
          call s:save_chars_with_secondary_highlights([char_p, char_s])
        endif
      endif

      " We've reached a new word, so reset any highlights.
      let [hi_p, hi_s] = [0, 0]
      let [char_p, char_s] = ['', '']

      let is_first_word = 0
    else
      if has_key(occurrences, char)
        let occurrences[char] += 1
      else
        let occurrences[char] = 1
      endif

      if !is_first_word
        let n = get(occurrences, char)

        " If the search is forward, we want to be greedy; otherwise, we want
        " to be reluctant. This prioritizes highlighting for characters at the
        " beginning of a word.
        "
        " If this is the first occurence of the letter in the word, mark it
        " for a highlight.
        if n == 1 && ((direction == 1 && hi_p == 0) || direction == 0)
          let hi_p = i + 1
          let char_p = char
        elseif n == 2 && ((direction == 1 && hi_s == 0) || direction == 0)
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

  if exists('g:qs_highlight_on_keys')
    call s:save_chars_with_secondary_highlights([char_p, char_s])
  endif

  return [patt_p, patt_s]
endfunction

" The direction can be 0 (backward), 1 (forward) or 2 (both). Targets are the
" characters that can be highlighted.
function! s:highlight_line(direction, targets)
  if g:qs_enable
    let line = getline(line('.'))
    let len = strlen(line)
    let pos = col('.')

    if !empty(line)
      " Highlight after the cursor.
      if a:direction != 0
        let [patt_p, patt_s] = s:get_highlight_patterns(line, pos, len, a:targets)
        call s:apply_highlight_patterns([patt_p, patt_s])
      endif

      " Highlight before the cursor.
      if a:direction != 1
        let pos -= 2
        if pos < 0 | let pos = 0 | endif

        let [patt_p, patt_s] = s:get_highlight_patterns(line, pos, -1, a:targets)
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

" Highlight on key press -----------------------------------------------------
" Manage state for keeping or removing the extra highlight after triggering a
" highlight on key press.
"
" State can be 0 (extra highlight has just been triggered), 1 (the cursor has
" moved while an extra highlight is active), or 2 (cancel an active extra
" highlight).
function! s:handle_extra_highlight(state)
  if a:state == 0
    let s:cursor_moved_count = 0
  elseif a:state == 1
    let s:cursor_moved_count = s:cursor_moved_count + 1
  endif

  " If the cursor has moved more than once since the extra highlight has been
  " active (or the state is 2), reset the extra highlight.
  if exists('s:cursor_moved_count') && (a:state == 2 ||  s:cursor_moved_count > 1)
    call s:unhighlight_line()
    call s:add_to_highlight_group(s:hi_group_secondary, 'fg', s:secondary_highlight_color)
    autocmd! quick_scope CursorMoved
  endif
endfunction

" Set or reset flags and state for highlighting on key press.
function! s:ready()
  " Direction of highlight search. 0 is backward, 1 is forward
  let s:direction = 0

  " The corresponding character to f,F,t or T
  let s:target = ''

  " Position of where a dummy cursor should be placed.
  let s:cursor = 0

  " Terminal and gui cursors which will be hidden and shown.
  let s:t_ve = &t_ve
  let s:guicursor = &guicursor

  " Characters with secondary highlights. Modified by get_highlight_patterns()
  let s:chars_s = []

  call s:handle_extra_highlight(2)

  " Intentionally return an empty string that will be concatenated with the
  " return values from aim(), reload() and double_tap().
  return ''
endfunction

" Returns {character motion}{captured char} (to map to a character motion) to
" emulate one as closely as possible.
function! s:aim(motion)
  if (a:motion ==# 'f' || a:motion ==# 't')
    let s:direction = 1
  else
    let s:direction = 0
  endif

  " Add a dummy cursor since calling getchar() places the actual cursor on
  " the command line.
  let s:cursor = matchadd(s:hi_group_cursor, '\%#', s:priority + 1)

  " Save and hide the cursor on the command line.
  let s:t_ve = &t_ve
  let s:guicursor = &guicursor

  set t_ve=
  set guicursor=n:block-NONE

  " Silence 'Type :quit<Enter> to exit Vim' message on <c-c> during a
  " character search.
  "
  " This line also causes getchar() to cleanly cancel on a <c-c>.
  execute 'nnoremap <silent> <c-c> <c-c>'

  call s:highlight_line(s:direction, s:accepted_chars)

  redraw

  " Store and capture the target for the character motion.
  let s:target = nr2char(getchar())

  return a:motion . s:target
endfunction

" Cleanup after a character motion is executed.
function! s:reload()
  " Remove dummy cursor
  call matchdelete(s:cursor)

  " Restore the cursor on the command line.
  set guicursor&
  let &t_ve = s:t_ve
  let &guicursor = s:guicursor

  " Restore default <c-c> functionality
  execute 'nunmap <c-c>'

  call s:unhighlight_line()

  " Intentionally return an empty string.
  return ''
endfunction

" Trigger an extra highlight for a target character only if it originally had
" a secondary highlight.
function! s:double_tap()
  if index(s:chars_s, s:target) != -1
    " Warning: slight hack below. Although the cursor has already moved by
    " this point, col('.') won't return the updated cursor position until the
    " invoking mapping completes. So when highlight_line() is called here, the
    " first occurrence of the target will be under the cursor, and the second
    " occurrence will be where the first occurence should have been.
    call s:highlight_line(s:direction, {expand(s:target) : ''})

    " Unhighlight only primary highlights (i.e., the character under the
    " cursor).
    for m in filter(getmatches(), printf('v:val.group ==# "%s"', s:hi_group_primary))
      call matchdelete(m.id)
    endfor

    " Temporarily change the second occurrence highlight color to a primary
    " highlight color.
    call s:add_to_highlight_group(s:hi_group_secondary, 'fg', s:primary_highlight_color)

    " Set a temporary event to keep track of when to reset the extra
    " highlight.
    augroup quick_scope
      autocmd CursorMoved * call s:handle_extra_highlight(1)
    augroup END

    call s:handle_extra_highlight(0)
  endif

  " Intentionally return an empty string.
  return ''
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
