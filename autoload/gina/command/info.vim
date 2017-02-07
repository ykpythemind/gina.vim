let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Path = vital#gina#import('System.Filepath')


function! gina#command#info#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let bufname = printf(
        \ 'gina://%s:info/%s',
        \ git.refname,
        \ args.params.object,
        \)
  call gina#core#buffer#open(bufname, {
        \ 'mods': a:mods,
        \ 'group': args.params.group,
        \ 'opener': args.params.opener,
        \ 'cmdarg': args.params.cmdarg,
        \ 'callback': {
        \   'fn': function('s:init'),
        \   'args': [args],
        \ }
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params = {}
  let args.params.async = args.pop('--async')
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.commit = gina#core#commit#resolve(a:git, args.pop(1, ''))
  let residual = args.residual()
  if len(residual) == 1
    let args.params.path = gina#core#repo#objpath(
          \ a:git, gina#core#repo#expand(residual[0])
          \)
    let args.params.object = args.params.commit . ':' . args.params.path
  else
    let args.params.path = ''
    let args.params.object = args.params.commit
  endif
  call args.set(0, 'show')
  call args.set(1, args.params.commit)
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal buftype=nowrite
  setlocal bufhidden=unload
  setlocal noswapfile
  setlocal nomodifiable

  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
  augroup END
endfunction

function! s:BufReadCmd() abort
  call gina#core#process#exec(
        \ gina#core#get_or_fail(),
        \ gina#core#meta#get_or_fail('args'),
        \)
  setlocal filetype=git
endfunction