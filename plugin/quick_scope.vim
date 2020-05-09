" Initialize -----------------------------------------------------------------
let s:plugin_name = 'quick-scope'

if exists('g:loaded_quick_scope')
  finish
endif

let g:loaded_quick_scope = 1

if &compatible
  echoerr s:plugin_name . " won't load in Vi-compatible mode."
  finish
endif

if v:version < 701 || (v:version == 701 && !has('patch040'))
  echoerr s:plugin_name . ' requires Vim running in version 7.1.040 or later.'
  finish
endif

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

if !exists('g:qs_lazy_highlight')
  let g:qs_lazy_highlight = 0
endif

if !exists('g:qs_second_highlight')
  let g:qs_second_highlight = 1
endif

if !exists('g:qs_ignorecase')
  let g:qs_ignorecase = 0
endif

if !exists('g:qs_max_chars')
  " Disable on long lines for performance
  let g:qs_max_chars = 1000
endif

if !exists('g:qs_accepted_chars')
  let g:qs_accepted_chars = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
endif

if !exists('g:qs_buftype_blacklist')
  let g:qs_buftype_blacklist = []
endif

if !exists('g:qs_highlight_on_keys')
  " Vanilla mode. Highlight on cursor movement.
  augroup quick_scope
    if g:qs_lazy_highlight
      autocmd CursorHold,InsertLeave,ColorScheme,WinEnter,BufEnter,FocusGained * call quick_scope#UnhighlightLine() | call quick_scope#HighlightLine(2, g:qs_accepted_chars)
    else
      autocmd CursorMoved,InsertLeave,ColorScheme,WinEnter,BufEnter,FocusGained * call quick_scope#UnhighlightLine() | call quick_scope#HighlightLine(2, g:qs_accepted_chars)
    endif
    autocmd InsertEnter,BufLeave,TabLeave,WinLeave,FocusLost * call quick_scope#UnhighlightLine()
  augroup END
else
  " Highlight on key press. Set an 'augmented' mapping for each defined key.
  for motion in filter(g:qs_highlight_on_keys, "v:val =~# '^[fFtT]$'")
    for mapmode in ['nnoremap', 'onoremap', 'xnoremap']
      execute printf(mapmode . ' <unique> <silent> <expr> %s quick_scope#Ready() . quick_scope#Aim("%s") . quick_scope#Reload() . quick_scope#DoubleTap()', motion, motion)
    endfor
  endfor
endif

" User commands --------------------------------------------------------------
command! -nargs=0 QuickScopeToggle call quick_scope#Toggle()

" Plug mappings --------------------------------------------------------------
nnoremap <silent> <plug>(QuickScopeToggle) :call quick_scope#Toggle()<cr>
xnoremap <silent> <plug>(QuickScopeToggle) :<c-u>call quick_scope#Toggle()<cr>

" Colors ---------------------------------------------------------------------
" Set the colors used for highlighting.
function! s:set_highlight_colors()
  " Priority for overruling other highlight matches.
  let g:qs_hi_priority = 1

  " Highlight group marking first appearance of characters in a line.
  let g:qs_hi_group_primary = 'QuickScopePrimary'
  " Highlight group marking second appearance of characters in a line.
  let g:qs_hi_group_secondary = 'QuickScopeSecondary'
  " Highlight group marking dummy cursor when quick-scope is enabled on key
  " press.
  let g:qs_hi_group_cursor = 'QuickScopeCursor'

  if exists('g:qs_first_occurrence_highlight_color')
    " backwards compatibility mode for old highlight configuration
    augroup quick_scope_lazy_print
      if has('vim_starting')
        " register this as a lazy print error so as not to block Vim starting
        autocmd CursorHold,CursorHoldI * call quick_scope#lazy_print#err('option g:qs_first_occurrence_highlight_color is deprecated!')
      else
        echohl ErrorMsg
        echomsg s:plugin_name . ' option g:qs_first_occurrence_highlight_color is deprecated!'
        echohl None
      endif
    augroup END

    let l:first_color = g:qs_first_occurrence_highlight_color
    if l:first_color =~# '#'
      execute 'highlight default ' . g:qs_hi_group_primary . ' gui=underline guifg=' . l:first_color
    else
      execute 'highlight default ' . g:qs_hi_group_primary . ' cterm=underline ctermfg=' . l:first_color
    endif
  else
    execute 'highlight default link ' . g:qs_hi_group_primary . ' Function'
  endif

  if exists('g:qs_second_occurrence_highlight_color')
    " backwards compatibility mode for old highlight configuration
    augroup quick_scope_lazy_print
      if has('vim_starting')
        " register this as a lazy print error so as not to block Vim starting
        autocmd CursorHold,CursorHoldI * call quick_scope#lazy_print#err('option g:qs_second_occurrence_highlight_color is deprecated!')
      else
        echohl ErrorMsg
        echomsg s:plugin_name . ' option g:qs_second_occurrence_highlight_color is deprecated!'
        echohl None
      endif
    augroup END

    let l:second_color = g:qs_second_occurrence_highlight_color
    if l:second_color =~# '#'
      execute 'highlight default ' . g:qs_hi_group_secondary . ' gui=underline guifg=' . l:second_color
    else
      execute 'highlight default ' . g:qs_hi_group_secondary . ' cterm=underline ctermfg=' . l:second_color
    endif
  else
    execute 'highlight default link ' . g:qs_hi_group_secondary . ' Define'
  endif

  execute 'highlight default link ' . g:qs_hi_group_cursor . ' Cursor'
endfunction

call s:set_highlight_colors()

let &cpo = s:cpo_save
unlet s:cpo_save
