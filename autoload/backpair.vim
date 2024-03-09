let s:rules = {}
let s:applicant_stack = []
let s:context = {}

function backpair#add_pair(opener, closer, opts = {}) abort
  if a:closer ==# ''
    call s:print_error('Closing pair must not be empty: opener: ' . string(a:opener))
    return
  endif

  let input = split(a:opener . a:closer, '\zs')
  let backlen = strchars(a:closer)

  let tree = s:rules
  for c in input
    if !has_key(tree, c)
      let tree[c] = {}
    endif
    let tree = tree[c]
  endfor
  let tree[input[-1]] = {'backlen': backlen, 'opts': a:opts}
endfunction

function backpair#clear_pairs() abort
  let s:rules = {}
endfunction

function backpair#enable() abort
  augroup plugin-backpair
    autocmd!
    autocmd InsertCharPre * call s:onInsertCharPre()
    autocmd InsertLeave * call s:onInsertLeave()
  augroup END
endfunction

function backpair#disable() abort
  augroup plugin-backpair
    autocmd!
  augroup END
  let s:applicant_stack = []
  let s:context = {}
endfunction

function s:print_error(msg) abort
  let msg = a:msg->split("\n")->map({_, v -> '[backpair] ' . v})
  echohl Error
  for m in msg
    echomsg m
  endfor
  echohl NONE
endfunction

function s:has_suffix(str, suf) abort
  return a:str->strpart(strlen(a:str) - strlen(a:suf)) ==# a:suf
endfunction

function s:check_availability(opts, ongoing_inputs) abort
  if get(a:opts, 'enable_filetypes', [&l:filetype])->index(&l:filetype) == -1
    return v:false
  elseif get(a:opts, 'disable_filetypes', [])->index(&l:filetype) != -1
    return v:false
  elseif !(get(a:opts, 'condition', {-> v:true})->call([]))
    return v:false
  endif

  let skip_if_ongoing = a:opts->get('skip_if_ongoing', [])
  for v in skip_if_ongoing
    if index(skip_if_ongoing, v) != -1
      return v:false
    endif
  endfor

  return v:true
endfunction

function s:onInsertCharPre() abort
  if !empty(s:context) && s:context.curpos != getpos('.')
    let s:context = {}
    let s:applicant_stack = []
  endif

  let line = getline('.')->strpart(0, col('.') - 1)
  call add(s:applicant_stack, [s:rules, ''])
  eval s:applicant_stack
    \->filter({_, v -> has_key(v[0], v:char) && s:has_suffix(line, v[1])})
    \->map({_, v -> [v[0][v:char], v[1] . v:char]})

  if empty(s:applicant_stack)
    let s:context = {}
    return
  endif

  " Check if there're any appliable rules.
  let ongoing_inputs = s:applicant_stack->copy()->map({_, v -> v[1]})
  for rule in s:applicant_stack
    if has_key(rule[0], 'backlen')  " Appliable rule is found.
      if !s:check_availability(rule[0].opts, ongoing_inputs)
        continue
      endif
      let v:char = ''
      call feedkeys(repeat("\<C-g>U\<left>", rule[0].backlen), 'ni')
      let s:applicant_stack = []
      let s:context = {}
      return
    endif
  endfor

  let curpos = getpos('.')
  let curpos[2] += strlen(v:char)
  let s:context = {
    \ 'curpos': curpos,
    \}
endfunction

function s:onInsertLeave() abort
  let s:applicant_stack = []
  let s:context = {}
endfunction

" Test helper function.
function s:script_vars() abort
  return s:
endfunction


" Fire User autocmd for initialization
augroup plugin-backpair-dummy
  autocmd!
  autocmd User backpair-initialize " Do nothing
augroup END

doautocmd User backpair-initialize

augroup plugin-backpair-dummy
  autocmd!
augroup END
