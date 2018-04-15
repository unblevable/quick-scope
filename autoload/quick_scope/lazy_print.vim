" function to wait to print error messages
function! quick_scope#lazy_print#err(message) abort
  augroup quick_scope_lazy_print
    autocmd!
    " clear the augroup so that these lazy loaded error messages only execute
    " once after starting
  augroup END
  echohl ErrorMsg
  echomsg 'quick_scope ' . a:message
  echohl None
endfunction
