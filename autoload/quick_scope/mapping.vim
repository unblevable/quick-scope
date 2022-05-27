" remap a key given a dictionary representing a saved mapping
function! quick_scope#mapping#Restore(mapping) abort
  " TODO: replace below with mapset()?
  let len_mode = strlen(a:mapping.mode)
  if len_mode == 0 || (len_mode == 1 && a:mapping.mode == ' ')
    " this handles special cases, see :help mapping-dict
    let len_mode = 3
    let a:mapping.mode = 'nvo'
  elseif len_mode == 1 && a:mapping.mode == '!'
    let len_mode = 2
    let a:mapping.mode = 'ic'
  endif
  let i = 0
  while i < len_mode
    execute a:mapping.mode[i]
          \ . (a:mapping.noremap ? 'noremap ' : 'map ')
          \ . (a:mapping.buffer ? '<buffer> ' : '')
          \ . (a:mapping.expr ? '<expr> ' : '')
          \ . (a:mapping.nowait ? '<nowait> ' : '')
          \ . (a:mapping.silent ? '<silent> ' : '')
          \ . a:mapping.lhs . ' '
          \ . substitute(escape(a:mapping.rhs, '|'), '<SID>', '<SNR>' . a:mapping.sid . '_', 'g')
    let i += 1
  endwhile
endfunction
