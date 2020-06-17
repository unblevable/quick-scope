" Autoload interface functions -------------------------------------------------

function! quick_scope#Toggle() abort
  if g:qs_enable
    let g:qs_enable = 0
    call quick_scope#UnhighlightLine()
  else
    let g:qs_enable = 1
    doautocmd CursorMoved
  endif
endfunction

" The direction can be 0 (backward), 1 (forward) or 2 (both). Targets are the
" characters that can be highlighted.
function! quick_scope#HighlightLine(direction, targets) abort
  if g:qs_enable && (!exists('b:qs_local_disable') || !b:qs_local_disable) && index(get(g:, 'qs_buftype_blacklist', []), &buftype) < 0
    let line = getline(line('.'))
    let len = strlen(line)
    let pos = col('.')

    if !empty(line) && len <= g:qs_max_chars
      " Highlight after the cursor.
      if a:direction != 0
        let [patt_p, patt_s] = s:get_highlight_patterns(line, pos, len, a:targets)
        call s:apply_highlight_patterns([patt_p, patt_s])
      endif

      " Highlight before the cursor.
      if a:direction != 1
        let [patt_p, patt_s] = s:get_highlight_patterns(line, pos, -1, a:targets)
        call s:apply_highlight_patterns([patt_p, patt_s])
      endif
    endif
  endif
endfunction

function! quick_scope#UnhighlightLine() abort
  for m in filter(getmatches(), printf('v:val.group ==# "%s" || v:val.group ==# "%s"', g:qs_hi_group_primary, g:qs_hi_group_secondary))
    call matchdelete(m.id)
  endfor
endfunction

" Set or reset flags and state for highlighting on key press.
function! quick_scope#Ready() abort
  " Direction of highlight search. 0 is backward, 1 is forward
  let s:direction = 0

  " The corresponding character to f,F,t or T
  let s:target = ''

  " Position of where a dummy cursor should be placed.
  let s:cursor = 0

  " Characters with secondary highlights. Modified by get_highlight_patterns()
  let s:chars_s = []

  call s:handle_extra_highlight(2)

  " Intentionally return an empty string that will be concatenated with the
  " return values from aim(), reload() and double_tap().
  return ''
endfunction

" Returns {character motion}{captured char} (to map to a character motion) to
" emulate one as closely as possible.
function! quick_scope#Aim(motion) abort
  if (a:motion ==# 'f' || a:motion ==# 't')
    let s:direction = 1
  else
    let s:direction = 0
  endif

  " Add a dummy cursor since calling getchar() places the actual cursor on
  " the command line.
  let s:cursor = matchadd(g:qs_hi_group_cursor, '\%#', g:qs_hi_priority + 1)

  " Silence 'Type :quit<Enter> to exit Vim' message on <c-c> during a
  " character search.
  "
  " This line also causes getchar() to cleanly cancel on a <c-c>.
  let b:qs_prev_ctrl_c_map = maparg('<c-c>', 'n', 0, 1)
  if empty(b:qs_prev_ctrl_c_map)
    unlet b:qs_prev_ctrl_c_map
  endif
  execute 'nnoremap <silent> <c-c> <c-c>'

  call quick_scope#HighlightLine(s:direction, g:qs_accepted_chars)

  redraw

  " Store and capture the target for the character motion.
  let char = getchar()
  let s:target = char ==# "\<S-lt>" ? '<' : nr2char(char)

  return a:motion . s:target
endfunction

" Cleanup after a character motion is executed.
function! quick_scope#Reload() abort
  " Remove dummy cursor
  call matchdelete(s:cursor)

  " Restore previous or default <c-c> functionality
  if exists('b:qs_prev_ctrl_c_map')
    call quick_scope#mapping#Restore(b:qs_prev_ctrl_c_map)
    unlet b:qs_prev_ctrl_c_map
  else
    execute 'nunmap <c-c>'
  endif

  call quick_scope#UnhighlightLine()

  " Intentionally return an empty string.
  return ''
endfunction

" Trigger an extra highlight for a target character only if it originally had
" a secondary highlight.
function! quick_scope#DoubleTap() abort
  if index(s:chars_s, s:target) != -1
    " Warning: slight hack below. Although the cursor has already moved by
    " this point, col('.') won't return the updated cursor position until the
    " invoking mapping completes. So when highlight_line() is called here, the
    " first occurrence of the target will be under the cursor, and the second
    " occurrence will be where the first occurence should have been.
    call quick_scope#HighlightLine(s:direction, [expand(s:target)])

    " Unhighlight only primary highlights (i.e., the character under the
    " cursor).
    for m in filter(getmatches(), printf('v:val.group ==# "%s"', g:qs_hi_group_primary))
      call matchdelete(m.id)
    endfor

    " Temporarily change the second occurrence highlight color to a primary
    " highlight color.
    call s:save_secondary_highlight()
    execute 'highlight! link ' . g:qs_hi_group_secondary . ' ' . g:qs_hi_group_primary

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

" Helpers ----------------------------------------------------------------------

" Apply the highlights for each highlight group based on pattern strings.
" Arguments are expected to be lists of two items.
function! s:apply_highlight_patterns(patterns) abort
  let [patt_p, patt_s] = a:patterns
  if !empty(patt_p)
    " Highlight columns corresponding to matched characters.
    "
    " Ignore the leading | in the primary highlights string.
    call matchadd(g:qs_hi_group_primary, '\v%' . line('.') . 'l(' . patt_p[1:] . ')', g:qs_hi_priority)
  endif
  if !empty(patt_s) && g:qs_second_highlight
    call matchadd(g:qs_hi_group_secondary, '\v%' . line('.') . 'l(' . patt_s[1:] . ')', g:qs_hi_priority)
  endif
endfunction

" Keep track of which characters have a secondary highlight (but no primary
" highlight) and store them in :chars_s. Used when g:qs_highlight_on_keys is
" active to decide whether to trigger an extra highlight.
function! s:save_chars_with_secondary_highlights(chars) abort
  let [char_p, char_s] = a:chars

  if !empty(char_p)
    " Do nothing
  elseif !empty(char_s)
    call add(s:chars_s, char_s)
  endif
endfunction

" Set or append to the pattern strings for the highlights.
function! s:add_to_highlight_patterns(patterns, highlights) abort
  let [patt_p, patt_s] = a:patterns
  let [hi_p, hi_s] = a:highlights

  " If there is a primary highlight for the last word, add it to the primary
  " highlight pattern.
  if hi_p > 0
    let patt_p = printf('%s|%%%sc', patt_p, hi_p)
  elseif hi_s > 0
    let patt_s = printf('%s|%%%sc', patt_s, hi_s)
  endif

  return [patt_p, patt_s]
endfunction

" Finds which characters to highlight and returns their column positions as a
" pattern string.
function! s:get_highlight_patterns(line, cursor, end, targets) abort
  " Keeps track of the number of occurrences for each target
  let occurrences = {}

  " Patterns to match the characters that will be marked with primary and
  " secondary highlight groups, respectively
  let [patt_p, patt_s] = ['', '']

  " Indicates whether this is the first word under the cursor. We don't want
  " to highlight any characters in it.
  let is_first_word = 1

  " We want to skip the first char as this is the char the cursor is at
  let is_first_char = 1

  " The position of a character in a word that will be given a highlight. A
  " value of 0 indicates there is no character to highlight.
  let [hi_p, hi_s] = [0, 0]

  " The (next) characters that will be given a highlight. Used by
  " save_chars_with_secondary_highlights() to see whether an extra highlight
  " should be triggered if g:qs_highlight_on_keys is active.
  let [char_p, char_s] = ['', '']

  " If 1, we're looping forwards from the cursor to the end of the line;
  " otherwise, we're looping from the cursor to the beginning of the line.
  let direction = a:cursor < a:end ? 1 : 0

  " find the character index i and the byte index c
  " of the current cursor position
  let c = 1
  let i = 0
  let char = ''
  while c != a:cursor
    let char = matchstr(a:line, '.', byteidx(a:line, i))
    let c += len(char)
    let i += 1
  endwhile

  " reposition cursor to end of the char's composing bytes
  if !direction
    let c += len(matchstr(a:line, '.', byteidx(a:line, i))) - 1
  endif

  " catch cases where multibyte chars may result in c not exactly equal to
  " a:end
  while (direction && c <= a:end || !direction && c >= a:end)

    let char = matchstr(a:line, '.', byteidx(a:line, i))

    " Skips the first char as it is the char the cursor is at
    if is_first_char

      let is_first_char = 0

    " Don't consider the character for highlighting, but mark the position
    " as the start of a new word.
    " use '\k' to check against keyword characters (see :help 'iskeyword' and
    " :help /\k)
    elseif char !~# '\k' || empty(char)
      if !is_first_word
        let [patt_p, patt_s] = s:add_to_highlight_patterns([patt_p, patt_s], [hi_p, hi_s])
      endif

      " We've reached a new word, so reset any highlights.
      let [hi_p, hi_s] = [0, 0]
      let [char_p, char_s] = ['', '']

      let is_first_word = 0
    elseif (index(a:targets, char) != -1 && !g:qs_ignorecase) || index(a:targets, tolower(char)) != -1
      if g:qs_ignorecase
        " When g:qs_ignorecase is set, make char_i the lowercase of char
        let char_i = tolower(char)
      else
        let char_i = char
      endif
      " Do all counting based on char_i in case we are doing ignorecase
      if has_key(occurrences, char_i)
        let occurrences[char_i] += 1
      else
        let occurrences[char_i] = 1
      endif

      if !is_first_word
        let char_occurrences = get(occurrences, char_i)
        " Below use char instead of char_i so that highlights get placed on the
        " correct character regardless of ignorecase

        " If the search is forward, we want to be greedy; otherwise, we
        " want to be reluctant. This prioritizes highlighting for
        " characters at the beginning of a word.
        "
        " If this is the first occurrence of the letter in the word,
        " mark it for a highlight.
        " If we are looking backwards, c will point to the end of the
        " composing bytes so we adjust accordingly
        " eg. with a multibyte char of length 3, c will point to the
        " 3rd byte. Minus (len(char) - 1) to adjust to 1st byte
        if char_occurrences == v:count1 && ((direction == 1 && hi_p == 0) || direction == 0)
          let hi_p = c - (1 - direction) * (len(char) - 1)
          let char_p = char
        elseif char_occurrences == (v:count1 + 1) && ((direction == 1 && hi_s == 0) || direction == 0)
          let hi_s = c - (1 - direction) * (len(char)- 1)
          let char_s = char
        endif
      endif
    endif

    " update i to next character
    " update c to next byteindex
    if direction == 1
      let i += 1
      let c += strlen(char)
    else
      let i -= 1
      let c -= strlen(char)
    endif
  endwhile

  let [patt_p, patt_s] = s:add_to_highlight_patterns([patt_p, patt_s], [hi_p, hi_s])

  if exists('g:qs_highlight_on_keys')
    call s:save_chars_with_secondary_highlights([char_p, char_s])
  endif

  return [patt_p, patt_s]
endfunction

" Save the value of g:qs_hi_group_secondary to preserve customization before
" changing it as a result of a double_tap
function! s:save_secondary_highlight() abort
  if &verbose
    let s:saved_verbose = &verbose
    set verbose=0
  endif

  redir => s:saved_secondary_highlight
  execute 'silent highlight ' . g:qs_hi_group_secondary
  redir END

  if exists('s:saved_verbose')
    execute 'set verbose=' . s:saved_verbose
  endif

  let s:saved_secondary_highlight = substitute(s:saved_secondary_highlight, '^.*xxx ', '', '')
endfunction

" Reset g:qs_hi_group_secondary to its saved value after it was changed as a result
" of a double_tap
function! s:reset_saved_secondary_highlight() abort
  if s:saved_secondary_highlight =~# '^links to '
    let s:saved_secondary_hlgroup_only = substitute(s:saved_secondary_highlight, '^links to ', '', '')
    execute 'highlight! link ' . g:qs_hi_group_secondary . ' ' . s:saved_secondary_hlgroup_only
  else
    execute 'highlight ' . g:qs_hi_group_secondary . ' ' . s:saved_secondary_highlight
  endif
endfunction

" Highlight on key press -----------------------------------------------------
" Manage state for keeping or removing the extra highlight after triggering a
" highlight on key press.
"
" State can be 0 (extra highlight has just been triggered), 1 (the cursor has
" moved while an extra highlight is active), or 2 (cancel an active extra
" highlight).
function! s:handle_extra_highlight(state) abort
  if a:state == 0
    let s:cursor_moved_count = 0
  elseif a:state == 1
    let s:cursor_moved_count = s:cursor_moved_count + 1
  endif

  " If the cursor has moved more than once since the extra highlight has been
  " active (or the state is 2), reset the extra highlight.
  if exists('s:cursor_moved_count') && (a:state == 2 ||  s:cursor_moved_count > 1)
    call quick_scope#UnhighlightLine()
    call s:reset_saved_secondary_highlight()
    autocmd! quick_scope CursorMoved
  endif
endfunction
