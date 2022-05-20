let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/Projects/docker-images/sealed-secrets-keys-backup
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
argglobal
%argdel
$argadd ~/Projects/personal/docker-images/sealed-secrets-master-key-backup
edit main.go
argglobal
balt ~/go/pkg/mod/sigs.k8s.io/yaml@v1.2.0/yaml.go
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let &fdl = &fdl
let s:l = 1 - ((0 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1
normal! 0
lcd ~/Projects/docker-images/sealed-secrets-keys-backup
tabnext 1
badd +41 ~/Projects/docker-images/sealed-secrets-keys-backup/main.go
badd +1 ~/Projects/personal/docker-images/sealed-secrets-master-key-backup
badd +158 /usr/local/go/src/encoding/json/encode.go
badd +4 ~/Projects/docker-images/sealed-secrets-keys-backup/k8s/deployment.yaml
badd +1 ~/Projects/docker-images/sealed-secrets-keys-backup/Dockerfile
badd +3 ~/Projects/docker-images/sealed-secrets-keys-backup/k8s/kustomization.yaml
badd +1 ~/Projects/docker-images/sealed-secrets-keys-backup/go.mod
badd +11 ~/Projects/docker-images/sealed-secrets-master-key-backup/main.go
badd +28 ~/Projects/docker-images/sealed-secrets-master-key-backup/Tiltfile
badd +9 ~/Projects/docker-images/sealed-secrets-master-key-backup/Dockerfile
badd +6 ~/Projects/personal/docker-images/sealed-secrets-master-key-backup/Tiltfile
badd +5 ~/Projects/personal/docker-images/sealed-secrets-master-key-backup/Dockerfile
badd +5 ~/Projects/docker-images/sealed-secrets-master-key-backup/k8s/deployment.yaml
badd +1 ~/Projects/docker-images/sealed-secrets-keys-backup/go.sum
badd +8 ~/Projects/docker-images/sealed-secrets-keys-backup/Tiltfile
badd +4 ~/Projects/docker-images/sealed-secrets-keys-backup/k8s/namespace.yaml
badd +36 ~/go/pkg/mod/k8s.io/client-go@v0.20.4/kubernetes/typed/core/v1/secret.go
badd +335 ~/go/pkg/mod/k8s.io/apimachinery@v0.20.4/pkg/apis/meta/v1/types.go
badd +82 ~/go/pkg/mod/sigs.k8s.io/yaml@v1.2.0/yaml.go
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToOFc
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
set hlsearch
let g:this_session = v:this_session
let g:this_obsession = v:this_session
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
