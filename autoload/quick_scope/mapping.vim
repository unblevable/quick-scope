" remap a key given a dictionary representing a saved mapping
function! quick_scope#mapping#Restore(mapping) abort
  execute a:mapping.mode
        \ . (a:mapping.noremap ? 'noremap ' : 'map ')
        \ . (a:mapping.buffer ? '<buffer> ' : '')
        \ . (a:mapping.expr ? '<expr> ' : '')
        \ . (a:mapping.nowait ? '<nowait> ' : '')
        \ . (a:mapping.silent ? '<silent> ' : '')
        \ . a:mapping.lhs . ' '
        \ . substitute(a:mapping.rhs, '<SID>', '<SNR>' . a:mapping.sid . '_', 'g')
endfunction
