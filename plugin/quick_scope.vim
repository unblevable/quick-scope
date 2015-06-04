" Disable loading plugin if...
if exists('g:loaded_quick_scope') || &compatible || v:version < 700
    finish
endif

let g:loaded_quick_scope = 1

" Define global settings here. This plugin doesn't have mappings.
function! quick_scope#init()
endfunction

" Save cpoptions and reassign them later.
" Avoid side effects for people with 'compatible' set. See :h use-cpo-save.
let s:cpo_save = &cpo
set cpo&vim

let &cpo = s:cpo_save
unlet s:cpo_save
