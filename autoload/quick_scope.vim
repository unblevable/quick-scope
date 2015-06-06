" Priority for overruling other highlight matches.
let s:priority = 100

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
    " secondary highlight groups, respectively.
    let hi_primary = ''
    let hi_secondary = ''

    " Used as a hash for uniqueness.
    let uniqueness = {}

    let special_chars = {'`': '', '-': '', '=': '', '[': '', ']': '', '\': '', ';': '', "'": '', ',': '', '.': '', '/': '', '~': '', '!': '', '@': '', '#': '', '$': '', '%': '', '^': '', '&': '', '*': '', '(': '', ')': '', '_': '', '+': '', '{': '', '}': '', '|': '', ':': '', '"': '', '<': '', '>': '', '?': '', "\n": '', "\r": ''}

    " Indicates whether a new Vim word has been reached
    let is_new_word = 1
    " Indicates whether the current word has been marked for any highlight
    let is_marked_for_hi = 0
    " The position of the character in the current word that has been marked for
    " a secondary highlight. A value of 0 indicates there is no highlight.
    " A word cannot have both a primary and secondary highlight.
    let char_hi_secondary = 0

    let i = a:start
    let do_increment = a:start < a:end ? 1 : 0
    while i != a:end
        let char = a:line[i]
        " Whitespace or a special character has been reached.
        " This set of comparisons is optimized, so it reads awkwardly.
        if char == "\<space>" || char == "\<tab>" || empty(char) || has_key(special_chars, char)
            let is_new_word = 1
            let is_marked_for_hi = 0

            " A secondary highlight still exists, i.e. the last word was not
            " highlighted. Prepare the last word for a secondary highlight.
            if char_hi_secondary > 0
                let hi_secondary = printf("%s|%%%sc", hi_secondary, char_hi_secondary)
                let char_hi_secondary = 0
            endif


        " The first time a character has appeared
        elseif !has_key(uniqueness, char)
            let uniqueness[char] = 1

            " If it is the start of a new word, prepare a primary highlight.
            if is_new_word == 1
                let is_new_word = 0
                let is_marked_for_hi = 1

                let hi_primary = printf("%s|%%%sc", hi_primary, i + 1)

                " The word has a primary highlight, so a secondary highlight is
                " no longer needed.
                let char_hi_secondary = 0
            endif

        " The character has already appeared.
        else
            " If the character has already appeared exactly once and the
            " current word not been marked yet, mark the current word for a
            " (secondary) highlight.
            if get(uniqueness, char) == 1 && is_marked_for_hi == 0
                let is_marked_for_hi = 1
                let char_hi_secondary = i + 1
            endif

            let uniqueness[char] += 1
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
