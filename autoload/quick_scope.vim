let s:priority = 100

" Helper functions
function! s:set_color(group, attr, color)
    let term = has('gui_running') ? 'gui' : 'cterm'

    execute printf("highlight %s %s%s=%s", a:group, term, a:attr, a:color)
endfunction

" Highlight
" execute 'highlight link QuickScopeF Function'
call s:set_color('QuickScopeF', '', 'underline')
call s:set_color('QuickScopeF', 'fg', 155)
call s:set_color('QuickScopeF', 'bg', 235)

function! s:highlight_custom(line, pos, len)
    let debug = ''
    let first_occurrences = ''
    let is_word = 1
    let unique = {}
    let i = a:pos
    while i < a:len
        " Ignore whitespace
        " if a:line[i] =~# '\v\s'
        if a:line[i] =~# '\v[`\-=[\]\\;'',./~!@#$%^&*()_+{}|:"<>?]|\s'
            " Do nothing.

        " Char has already occurred.
        elseif has_key(unique, a:line[i])
            let unique[a:line[i]] += 1

        " First time char has occurred.
        else
            let debug = debug . a:line[i]
            let unique[a:line[i]] = 1

            " If not start of new word, don't highlight.
            if is_word != 0
                let first_occurrences = printf("%s|%%%sc", first_occurrences, i + 1)
                let is_word = 0
            endif
        endif

        " A special character or whitespace denotes a new word.
        if a:line[i] =~# '\v[`\-=[\]\\;'',./~!@#$%^&*()_+{}|:"<>?]|\s'
            let is_word = 1
        endif


        let i += 1
    endwhile

    echom debug

    if !empty(first_occurrences)
        call matchadd('QuickScopeF', '\v%' . line('.') . 'l(' . first_occurrences[1:] . ')', s:priority + 2)
    endif
endfunction

" Main functions
function! s:highlight_line()
    let line = getline(line('.'))
    let len = strlen(line)
    let pos = col('.')

    if empty(line)
        let pos = 0
    endif

    call s:highlight_custom(line, pos, len)
endfunction

function! s:unhighlight_line()
    for m in filter(getmatches(), 'v:val.group ==# "QuickScopeF"')
        call matchdelete(m.id)
    endfor
endfunction

" Autoload
augroup quick_scope
    autocmd!
    autocmd CursorMoved,InsertLeave,ColorScheme * call s:unhighlight_line() | call s:highlight_line()
    autocmd InsertEnter * call s:unhighlight_line()
augroup END
