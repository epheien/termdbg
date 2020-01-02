
let s:config = {}
let s:config['prompt'] = 'ipdb> '
let s:config['trim_ansi_escape'] = v:true

func backend#ipdb#Get()
  return s:config
endfunc

" vi:set sts=2 sw=2 et:
