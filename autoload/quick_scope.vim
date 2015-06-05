let s:f_color = 081
let s:t_color = 050
let s:priority = 100

let s:curr_lnum = line('.')
let s:prev_lnum = s:curr_lnum
let s:line = getline(s:curr_lnum)


" let s:group_names = [
"     'QuickScopePrimary',
"     'QuickScopeSecondary'
" ]

" Helper functions
function! s:set_color(group, attr, color)
    let term = has('gui_running') ? 'gui' : 'cterm'

    execute printf("highlight %s %s%s=%s", a:group, term, a:attr, a:color)
endfunction

" Highlight
execute 'highlight link QuickScopeDim Normal'
execute 'highlight link QuickScopeF Function'
execute 'highlight link QuickScopeF2 Keyword'
" call s:set_color('QuickScopeF', 'fg', 118)
" call s:set_color('QuickScopeF', 'fg', 87)
" call s:set_color('QuickScopeF2', 'fg', 157)
" call s:set_color('QuickScopeDim', 'fg', '015')

function! s:highlight_chars(chars)""
    call matchadd('QuickScopeF', '\v%' . line('.') . 'l' . '\zs\f\f' . join(a:chars, '') . '\)\{1}', s:priority)
endfunction

" Get a list of unique characters from a string.
function! s:get_unique_chars(str)
    " Get all unique characters in string as keys in a dict
    let unique = {}
    let i = 0
    let len = strlen(a:str)
    while i < len
        let unique[a:str[i]] = ''
        let i += 1
    endwhile

    return keys(unique)
endfunction

function! s:highlight_custom(line, pos, len)
    let debug = ''
    let debug2 = ''
    let debug3 = ''
    let first_occurrences = ''
    let second_occurrences = ''
    let unique = {}
    let i = a:pos
    echom a:pos . '+' . a:len
    while i < a:len
        " Char has occured at least twice already.
        if has_key(unique, a:line[i] . a:line[i])
            let debug3 = debug3 . a:line[i]
            " Do nothing.
        " Char has occured at least once already.
        elseif has_key(unique, a:line[i])
            let debug2 = debug2 . a:line[i]
            let unique[a:line[i] . a:line[i]] = ''
            let second_occurrences = printf("%s|%%%sc", second_occurrences, i + 1)
        " First time char has occured
        else
            let debug = debug . a:line[i]
            let unique[a:line[i]] = ''
            let first_occurrences = printf("%s|%%%sc", first_occurrences, i + 1)
        endif

        let i += 1
    endwhile

    call matchadd('QuickScopeDim', '\v%' . line('.') . 'l', s:priority)
    if !empty(first_occurrences)
        call matchadd('QuickScopeF', '\v%' . line('.') . 'l(' . first_occurrences[1:] . ')', s:priority + 2)
    endif
    if !empty(second_occurrences)
        call matchadd('QuickScopeF2', '\v%' . line('.') . 'l(' . second_occurrences[1:] . ')', s:priority + 1)
    endif

    echom second_occurrences
endfunction

" Main functions
function! s:highlight_line()
    for m in filter(getmatches(), 'v:val.group ==# "QuickScopeF" || v:val.group ==# "QuickScopeDim" || v:val.group ==# "QuickScopeF2"')
        call matchdelete(m.id)
    endfor
    let s:curr_lnum = line('.')

    " if s:curr_lnum == s:prev_lnum
    "     echo 'same line'
    " else
        let s:prev_lnum = s:curr_lnum
        let s:line = getline(s:curr_lnum)
        " Length of line without \n
        let s:len = strlen(s:line)

        " Get cursor position, zero-indexed
        let pos = col('.')

        " Guards
        if pos < 0 || empty(s:line)
            let pos = 0
        " elseif pos >= s:len
        "     let pos = s:len
        endif

        " Get bufline before cursor, exclusive; guard against when cursor is at
        " beginning of line
        " let before = s:line[: (pos == 0 ? 0 : pos - 1)]

        " Get bufline after cursor, exclusive; guard against when cursor is at
        " end of line
        " let after = s:line[(pos == len(s:line) - 1 ? pos : pos + 1) :]

        " echo s:get_unique_chars(substitute(before, '\s', '', 'g'))
        " call s:highlight_chars(s:get_unique_chars(substitute(after, '\s', '', 'g')))

        call s:highlight_custom(s:line, pos, s:len)
    " endif

    " If leaving insert mode reconstruct line
    " If on line don't reconstruct line
    " When moving new lines, reconstruct line
    " Mark first occurence of each letter.
    " let pattern = '\v%' . line('.') . 'l' . '
    "
    " :h search-range
endfunction

function! s:unhighlight_line()
    " Do nothing for now.
endfunction

" Autoload
augroup quick_scope
    autocmd!
    autocmd CursorMoved,InsertLeave,ColorScheme * call s:highlight_line()
    autocmd InsertEnter * call s:unhighlight_line()
augroup END
