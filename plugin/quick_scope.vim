let s:plugin_name = "quick-scope"

" Disable loading the plugin if...
if exists('g:loaded_quick_scope')
    finish
endif

if &cp
    echoerr s:plugin_name . " cannot be initialized because of errors."
    finish
endif

if &compatible
    echoerr s:plugin_name . " won't load in Vi-compatible mode."
    finish
endif

" @todo: Actually test which versions of Vim this plugin supports.
if v:version < 700
    echoerr s:plugin_name . " requires Vim running in version 7 or later."
endif

let g:loaded_quick_scope = 1

" Save cpoptions and reassign them later. See :h use-cpo-save.
let s:cpo_save = &cpo
set cpo&vim

" command! -nargs=0 QuickScopeToggle call quick_scope#toggle()
command! -nargs=0 QuickScopeToggle call quick_scope#toggle()

let &cpo = s:cpo_save
unlet s:cpo_save
