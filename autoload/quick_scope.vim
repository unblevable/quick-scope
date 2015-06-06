" Priority for overruling other highlight matches.
let s:priority = 1000

function! s:highlight_forward(line, pos, len)
    let hi_primary = ''
    let unique = {}
    let is_new_word = 1

    let i = a:pos
    while i < a:len
        let char = a:line[i]

        " Start a new word when a special character or whitespace is met, but
        " don't highlight them.
        if char =~# '\v[`\-=[\]\\;'',./~!@#$%^&*()_+{}|:"<>?]|\s'
            let is_new_word = 1

        " Character has already appeared on the line.
        elseif has_key(unique, char)
            let unique[char] += 1

        " First time character has appeared.
        else
            " let debug = debug . a:line[i]
            let unique[char] = 1

            " If not start of new word, don't highlight.
            if is_new_word == 1
                let hi_primary = printf("%s|%%%sc", hi_primary, i + 1)
                let is_new_word = 0
            endif
        endif

        let i += 1
    endwhile

    " echom debug

    if !empty(hi_primary)
        " Highlight columns corresponding to matched characters (Ignore the leading
        " | in the primary highlights string.)
        call matchadd('QuickScopeF', '\v%' . line('.') . 'l(' . hi_primary[1:] . ')', s:priority)
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
    for m in filter(getmatches(), 'v:val.group ==# "QuickScopeF"')
        call matchdelete(m.id)
    endfor
endfunction

" Helper functions
function! s:set_color(group, attr, color)
    let term = has('gui_running') ? 'gui' : 'cterm'

    execute printf("highlight %s %s%s=%s", a:group, term, a:attr, a:color)
endfunction

" execute 'highlight link QuickScopeF Function'
call s:set_color('QuickScopeF', '', 'underline')
call s:set_color('QuickScopeF', 'fg', 155)
call s:set_color('QuickScopeF', 'bg', 235)

" Autoload
augroup quick_scope
    autocmd!
    autocmd CursorMoved,InsertLeave,ColorScheme * call s:unhighlight_line() | call s:highlight_line()
    autocmd InsertEnter * call s:unhighlight_line()
augroup END
