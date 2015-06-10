let g:qs_disable = 0

" Priority for overruling other highlight matches.
let s:priority = 1

" Highlight group marking first appearance of characters in a line.
let s:hi_group_primary = 'QuickScopePrimary'

" Highlight group marking second appearance of characters in a line.
let s:hi_group_secondary = 'QuickScopeSecondary'

" Helper functions
function! s:set_color(group, attr, color)
    let term = has('gui_running') ? 'gui' : 'cterm'

    execute printf("highlight %s %s%s=%s", a:group, term, a:attr, a:color)
endfunction

" Main functions
function! s:highlight_from_to(line, start, end)
    " Patterns to match the characters that will be marked with primary and
    " secondary highlight groups, respectively
    let hi_primary = ''
    let hi_secondary = ''

    " Keys correspond to characters that can be highlighted. Values refer to
    " occurrences of each character on a line.
    let accepted_chars = {'a': 0, 'b': 0, 'c': 0, 'd': 0, 'e': 0, 'f': 0, 'g': 0, 'h': 0, 'i': 0, 'j': 0, 'k': 0, 'l': 0, 'm': 0, 'n': 0, 'o': 0, 'p': 0, 'q': 0, 'r': 0, 's': 0, 't': 0, 'u': 0, 'v': 0, 'w': 0, 'x': 0, 'y': 0, 'z': 0, 'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0, 'F': 0, 'G': 0, 'H': 0, 'I': 0, 'J': 0, 'K': 0, 'L': 0, 'M': 0, 'N': 0, 'O': 0, 'P': 0, 'Q': 0, 'R': 0, 'S': 0, 'T': 0, 'U': 0, 'V': 0, 'W': 0, 'X': 0, 'Y': 0, 'Z': 0, '0': 0, '1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0,}

    " Indicates whether a Vim word has been highlighted
    let is_word_hi = 0

    " The position of a character in a word that could possibly be given a
    " secondary highlight. A value of 0 indicates there is no character to
    " highlight.
    let to_hi_secondary = 0

    " Max numbers of characters to search on a line
    let max = 100

    " Loop up or down depending on start and end points.
    let do_increment = a:start < a:end ? 1 : 0

    let i = a:start
    while i != a:end
        let char = a:line[i]

        " Don't consider the character for highlighting. Check for a <space> as
        " a first condition for optimization.
        if char == "\<space>" || !has_key(accepted_chars, char) || empty(char)
            " The last word has not been highlighted yet. Add a secondary
            " highlight if it exists.
            if !is_word_hi && to_hi_secondary > 0
                let hi_secondary = printf("%s|%%%sc", hi_secondary, to_hi_secondary)
                let to_hi_secondary = 0
            endif

            " A new word has been reached. Reset the highlight flag.
            let is_word_hi = 0
        else
            let accepted_chars[char] += 1

            if !is_word_hi
                let occurrences = get(accepted_chars, char)

                if occurrences == 1
                    let hi_primary = printf("%s|%%%sc", hi_primary, i + 1)
                    let is_word_hi = 1

                " The char has appeared twice, so prepare it for a possible
                " secondary highlight.
                elseif occurrences == 2 && to_hi_secondary == 0
                    let to_hi_secondary = i + 1
                    let is_word_hi = 1
                endif
            endif
        endif

        if do_increment == 1
            let i += 1
        else
            let i -= 1
        endif
    endwhile

    if !empty(hi_primary)
        " Highlight columns corresponding to matched characters
        " Ignore the leading | in the primary highlights string.
        call matchadd(s:hi_group_primary, '\v%' . line('.') . 'l(' . hi_primary[1:] . ')', s:priority)
    endif
    if !empty(hi_secondary)
        call matchadd(s:hi_group_secondary, '\v%' . line('.') . 'l(' . hi_secondary[1:] . ')', s:priority)
    endif
endfunction

function! s:highlight_line()
    if !g:qs_disable
        let line = getline(line('.'))
        let len = strlen(line)

        let pos = col('.')

        if !empty(line)
            " Highlight after the cursor.
            call s:highlight_from_to(line, pos, len)

            let pos -= 2
            if pos < 0
                let pos = 0
            endif

            " Highlight before the cursor.
            call s:highlight_from_to(line, pos, 1)
        endif
    endif
endfunction

function! s:unhighlight_line()
    for m in filter(getmatches(), printf('v:val.group ==# "%s" || v:val.group ==# "%s"', s:hi_group_primary, s:hi_group_secondary))
        call matchdelete(m.id)
    endfor
endfunction

call s:set_color(s:hi_group_primary, '', 'underline')
call s:set_color(s:hi_group_primary, 'fg', 155)
call s:set_color(s:hi_group_secondary, '', 'underline')
call s:set_color(s:hi_group_secondary, 'fg', 087)

" Preserve the background color of cursorline if it exists.
if &cursorline
    let bg = synIDattr(hlID('CursorLine'), 'bg')
    call s:set_color(s:hi_group_primary, 'bg', bg)
    call s:set_color(s:hi_group_secondary, 'bg', bg)
endif

" Autoload
augroup quick_scope
    autocmd!
    autocmd CursorMoved,InsertLeave,ColorScheme * call s:unhighlight_line() | call s:highlight_line()
    autocmd InsertEnter * call s:unhighlight_line()
augroup END
