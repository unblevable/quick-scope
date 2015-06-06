" Priority for overruling other highlight matches.
let s:priority = 1000
let s:hi_group_primary = 'QuickScopePrimary'
let s:hi_group_secondary = 'QuickScopeSecondary'

function! s:highlight_forward(line, pos, len)
    let hi_primary = ''
    let hi_secondary = ''
    let uniqueness = {}
    let special_chars = {'`': '', '-': '', '=': '', '[': '', ']': '', '\': '', ';': '', "'": '', ',': '', '.': '', '/': '', '~': '', '!': '', '@': '', '#': '', '$': '', '%': '', '^': '', '&': '', '*': '', '(': '', ')': '', '_': '', '+': '', '{': '', '}': '', '|': '', ':': '', '"': '', '<': '', '>': '', '?': '',}
    let is_new_word = 1

    let is_word_hi = 0
    let letter = ''

    let i = a:pos
    while i < a:len
        let char = a:line[i]

        " Start a new word when a special character or whitespace is met, but
        " don't process it for highlighting.
        if char == ' ' || char == '	' || has_key(special_chars, char) || i == a:len - 1
            let is_new_word = 1
            " echom i . ':' a:len

            " If the previous word has not been highlighted yet, prepare it for
            " a secondary highlight
            if !empty(letter) && is_word_hi == 0
                let hi_secondary = printf("%s|%%%sc", hi_secondary, i)

                let is_word_hi = 1
                let letter = ''
            endif

        " Character has already appeared on the line.
        elseif has_key(uniqueness, char)
            if get(uniqueness, char) == 1 && empty(letter)
                let letter = char
                " echom letter
            endif

            let uniqueness[char] += 1

        " First time character has appeared.
        else
            " let debug = debug . a:line[i]
            let uniqueness[char] = 1

            " If start of a new word, prepare the highlight.
            if is_new_word == 1
                let hi_primary = printf("%s|%%%sc", hi_primary, i + 1)
                let is_new_word = 0
                let is_word_hi = 1
            endif
        endif

        let i += 1
    endwhile

    " echom debug
    " echom hi_secondary

    if !empty(hi_primary)
        " Highlight columns corresponding to matched characters (Ignore the leading
        " | in the primary highlights string.)
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
            call s:highlight_forward(line, pos, len)
    endif
endfunction

function! s:unhighlight_line()
    for m in filter(getmatches(), printf('v:val.group ==# "%s" || v:val.group ==# "%s"', s:hi_group_primary, s:hi_group_secondary))
        call matchdelete(m.id)
    endfor
endfunction

" Helper functions
function! s:set_color(group, attr, color)
    let term = has('gui_running') ? 'gui' : 'cterm'

    execute printf("highlight %s %s%s=%s", a:group, term, a:attr, a:color)
endfunction

" execute 'highlight link ' . s:hi_group_primary . ' Function'
call s:set_color(s:hi_group_primary, '', 'underline')
call s:set_color(s:hi_group_primary, 'fg', 155)
call s:set_color(s:hi_group_primary, 'bg', 235)
call s:set_color(s:hi_group_secondary, '', 'underline')
call s:set_color(s:hi_group_secondary, 'fg', 087)
call s:set_color(s:hi_group_secondary, 'bg', 235)

" Autoload
augroup quick_scope
    autocmd!
    autocmd CursorMoved,InsertLeave,ColorScheme * call s:unhighlight_line() | call s:highlight_line()
    autocmd InsertEnter * call s:unhighlight_line()
augroup END
