function s:internal_error_message(msg) abort
  return 'helper/scripter.vim: internal error:' . a:msg
endfunction

function s:replace_termcodes(from) abort
  return substitute(a:from, '<[^<]\+>',
   \ '\=eval(printf(''"\%s"'', submatch(0)))', 'g')
endfunction


let s:scripter = {
  \ '_script': [],
  \ '_fn_stack': [],
  \ '_fn_consumer': v:null
  \ }

function s:scripter._init() abort
  let self._fn_consumer = {-> self._call_top_of_fn_stack()}
  call themis#func_alias(self)
  return self
endfunction

function s:scripter._call_top_of_fn_stack() abort
  if empty(self._fn_stack)
    throw s:internal_error_message('Function stack is empty.')
  endif

  call call(remove(self._fn_stack, 0), [])
endfunction

function s:scripter.call(Fn) abort
  call add(self._fn_stack, a:Fn)
  call add(self._script,
    \ printf("\<Cmd>call call(%s, [])\<CR>", self._fn_consumer))
  return self
endfunction

function s:scripter.feedkeys(keys) abort
  call add(self._script, s:replace_termcodes(a:keys))
  return self
endfunction

function s:scripter.run() abort
  let script = join(self._script, '')
  let self._script = []
  call feedkeys(script, 'nix')
  if !empty(self._fn_stack)
    throw s:internal_error_message(
      \ '_fn_stack still have entries: ' . string(self._fn_stack))
  endif
  return self
endfunction

function NewScripter() abort
  return deepcopy(s:scripter)._init()
endfunction
