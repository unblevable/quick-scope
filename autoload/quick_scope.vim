let s:priority = 100

" Helper functions
function! s:set_color(group, attr, color)
    let term = has('gui_running') ? 'gui' : 'cterm'

    execute printf("highlight %s %s%s=%s", a:group, term, a:attr, a:color)
endfunction

" Highlight
" execute 'highlight link QuickScopeF Function'
" call s:set_color('QuickScopeF', '', 'underline')
call s:set_color('QuickScopeF', 'fg', 155)
call s:set_color('QuickScopeF', 'bg', 'white')

function! s:highlight_custom(line, pos, len)
    let debug = ''
    let first_occurrences = ''
    let unique = {}
    let i = a:pos
    while i < a:len
        " First time char has occured
        if has_key(unique, a:line[i])
            let debug = debug . a:line[i]
            let unique[a:line[i]] = ''
            let first_occurrences = printf("%s|%%%sc", first_occurrences, i + 1)
        endif

        let i += 1
    endwhile

    if !empty(first_occurrences)
        call matchadd('QuickScopeF', '\v%' . line('.') . 'l(' . first_occurrences[1:] . ')', s:priority + 2)
    endif
endfunction

" Main functions
function! s:highlight_line()
    call s:unhighlight_line()

    let s:line = getline(line('.'))

    let s:len = strlen(s:line)

    " Get cursor position, zero-indexed
    let pos = col('.')

    " Guards
    if empty(s:line)
        let pos = 0
    endif

    call s:highlight_custom(s:line, pos, s:len)

    " :h search-range
endfunction

function! s:unhighlight_line()
    for m in filter(getmatches(), 'v:val.group ==# "QuickScopeF"')
        call matchdelete(m.id)
    endfor
endfunction

" Autoload
augroup quick_scope
    autocmd!
    autocmd CursorMoved,InsertLeave,ColorScheme * call s:highlight_line()
    autocmd InsertEnter * call s:unhighlight_line()
augroup END
