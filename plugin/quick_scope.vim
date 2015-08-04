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

if !exists('g:qs_enable')
    let g:qs_enable = 1
endif

" User commands ----------------------------------------------------------------
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

" Plug mappings ----------------------------------------------------------------
nnoremap <silent> <plug>(QuickScopeToggle) :call <sid>toggle()<cr>
vnoremap <silent> <plug>(QuickScopeToggle) :<c-u>call <sid>toggle()<cr>

" Autoload ---------------------------------------------------------------------
augroup quick_scope
    autocmd!
    autocmd CursorMoved,InsertLeave,ColorScheme * call s:unhighlight_line() | call s:highlight_line()
    autocmd InsertEnter * call s:unhighlight_line()
    autocmd VimEnter,ColorScheme * call s:set_highlight_colors()
augroup END

" Colors -----------------------------------------------------------------------
" Priority for overruling other highlight matches.
let s:priority = 1

" Highlight group marking first appearance of characters in a line.
let s:hi_group_primary = 'QuickScopePrimary'
let s:hi_group_secondary = 'QuickScopeSecondary'

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
  endif

  if !exists('g:qs_second_occurrence_highlight_color')
      " set color to match 'Keyword' highlight group or cyan
      let g:qs_second_occurrence_highlight_color = s:set_default_color('Define', '#5fffff', 81, 14)
  endif

  call s:add_to_highlight_group(s:hi_group_primary, '', 'underline')
  call s:add_to_highlight_group(s:hi_group_primary, 'fg', g:qs_first_occurrence_highlight_color)
  call s:add_to_highlight_group(s:hi_group_secondary, '', 'underline')
  call s:add_to_highlight_group(s:hi_group_secondary, 'fg', g:qs_second_occurrence_highlight_color)

  " Preserve the background color of cursorline if it exists.
  if &cursorline
      let bg_color = synIDattr(synIDtrans(hlID('CursorLine')), 'bg', s:get_term())

      if bg_color != -1
        call s:add_to_highlight_group(s:hi_group_primary, 'bg', bg_color)
        call s:add_to_highlight_group(s:hi_group_secondary, 'bg', bg_color)
      endif
  endif
endfunction

" Primary functions ------------------------------------------------------------
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
function! s:get_highlight_patterns(line, start, end)
    " Patterns to match the characters that will be marked with primary and
    " secondary highlight groups, respectively
    let [patt_p, patt_s] = ['', '']

    " Keys correspond to characters that can be highlighted. Values refer to
    " occurrences of each character on a line.
    let accepted_chars = {'a': 0, 'b': 0, 'c': 0, 'd': 0, 'e': 0, 'f': 0, 'g': 0, 'h': 0, 'i': 0, 'j': 0, 'k': 0, 'l': 0, 'm': 0, 'n': 0, 'o': 0, 'p': 0, 'q': 0, 'r': 0, 's': 0, 't': 0, 'u': 0, 'v': 0, 'w': 0, 'x': 0, 'y': 0, 'z': 0, 'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0, 'F': 0, 'G': 0, 'H': 0, 'I': 0, 'J': 0, 'K': 0, 'L': 0, 'M': 0, 'N': 0, 'O': 0, 'P': 0, 'Q': 0, 'R': 0, 'S': 0, 'T': 0, 'U': 0, 'V': 0, 'W': 0, 'X': 0, 'Y': 0, 'Z': 0, '0': 0, '1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0,}

    " Indicates whether this is the first word under the cursor. We don't want
    " to highlight any characters in it.
    let is_first_word = 1

    " The position of a character in a word that will be given a highlight. A
    " value of 0 indicates there is no character to highlight.
    let [hi_p, hi_s] = [0, 0]

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
            endif

            " We've reached a new word, so reset any highlights.
            let [hi_p, hi_s] = [0, 0]

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
                elseif occurrences == 2 && ((direction == 1 && hi_s == 0) || direction == 0)
                    let hi_s = i + 1
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

    return [patt_p, patt_s]
endfunction

function! s:highlight_line()
    if g:qs_enable
        let line = getline(line('.'))
        let len = strlen(line)
        let pos = col('.')

        if !empty(line)
            " Highlights after the cursor.
            let [patt_p, patt_s] = s:get_highlight_patterns(line, pos, len)
            call s:apply_highlight_patterns([patt_p, patt_s])

            let pos -= 2
            if pos < 0 | let pos = 0 | endif

            " Highlights before the cursor.
            let [patt_p, patt_s] = s:get_highlight_patterns(line, pos, -1)
            call s:apply_highlight_patterns([patt_p, patt_s])
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
