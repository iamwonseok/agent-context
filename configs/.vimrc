" ==========================================
" Project-local Vim Configuration
" Based on .editorconfig settings
" Place in project root or source with:
"   autocmd BufRead,BufNewFile /path/to/project/* source /path/to/project/.vimrc
" ==========================================

" ==========================================
" 1. 기본 설정 (All Files)
" ==========================================
set encoding=utf-8
set fileformat=unix          " Unix line endings (LF)
set fileformats=unix,dos     " Prefer Unix, fallback to DOS

" Trailing whitespace 표시
set list
set listchars=tab:»\ ,trail:·,extends:>,precedes:<

" 파일 저장 시 trailing whitespace 제거 (선택적)
" autocmd BufWritePre * :%s/\s\+$//e


" ==========================================
" 2. C/C++ 설정 (*.c, *.h, *.cpp, *.hpp)
" 탭 들여쓰기, 탭 크기 4, 최대 100자
" ==========================================
augroup CFileSettings
	autocmd!
	autocmd FileType c,cpp setlocal noexpandtab
	autocmd FileType c,cpp setlocal tabstop=4
	autocmd FileType c,cpp setlocal shiftwidth=4
	autocmd FileType c,cpp setlocal softtabstop=4
	autocmd FileType c,cpp setlocal colorcolumn=100
	autocmd FileType c,cpp setlocal textwidth=100
augroup END


" ==========================================
" 3. Bash/Shell 설정 (*.sh)
" 탭 들여쓰기, 탭 크기 4, 최대 100자
" ==========================================
augroup ShellFileSettings
	autocmd!
	autocmd FileType sh,bash setlocal noexpandtab
	autocmd FileType sh,bash setlocal tabstop=4
	autocmd FileType sh,bash setlocal shiftwidth=4
	autocmd FileType sh,bash setlocal softtabstop=4
	autocmd FileType sh,bash setlocal colorcolumn=100
	autocmd FileType sh,bash setlocal textwidth=100
augroup END


" ==========================================
" 4. Makefile 설정 (Makefile, *.mk)
" 레시피는 반드시 탭
" ==========================================
augroup MakeFileSettings
	autocmd!
	autocmd FileType make setlocal noexpandtab
	autocmd FileType make setlocal tabstop=4
	autocmd FileType make setlocal shiftwidth=4
	autocmd FileType make setlocal softtabstop=4
augroup END


" ==========================================
" 5. Python 설정 (*.py)
" 공백 4칸, 최대 88자 (Black 기본값)
" ==========================================
augroup PythonFileSettings
	autocmd!
	autocmd FileType python setlocal expandtab
	autocmd FileType python setlocal tabstop=4
	autocmd FileType python setlocal shiftwidth=4
	autocmd FileType python setlocal softtabstop=4
	autocmd FileType python setlocal colorcolumn=88
	autocmd FileType python setlocal textwidth=88
augroup END


" ==========================================
" 6. YAML 설정 (*.yml, *.yaml)
" 공백 2칸
" ==========================================
augroup YamlFileSettings
	autocmd!
	autocmd FileType yaml setlocal expandtab
	autocmd FileType yaml setlocal tabstop=2
	autocmd FileType yaml setlocal shiftwidth=2
	autocmd FileType yaml setlocal softtabstop=2
augroup END


" ==========================================
" 7. JSON 설정 (*.json)
" 공백 2칸
" ==========================================
augroup JsonFileSettings
	autocmd!
	autocmd FileType json setlocal expandtab
	autocmd FileType json setlocal tabstop=2
	autocmd FileType json setlocal shiftwidth=2
	autocmd FileType json setlocal softtabstop=2
augroup END


" ==========================================
" 8. Markdown 설정 (*.md)
" 공백 2칸, trailing whitespace 유지 (줄바꿈용)
" ==========================================
augroup MarkdownFileSettings
	autocmd!
	autocmd FileType markdown setlocal expandtab
	autocmd FileType markdown setlocal tabstop=2
	autocmd FileType markdown setlocal shiftwidth=2
	autocmd FileType markdown setlocal softtabstop=2
	" Markdown에서는 trailing whitespace가 줄바꿈 의미
	autocmd FileType markdown setlocal listchars=tab:»\ ,extends:>,precedes:<
augroup END


" ==========================================
" 9. Dockerfile 설정
" 공백 4칸
" ==========================================
augroup DockerfileSettings
	autocmd!
	autocmd BufNewFile,BufRead Dockerfile* setfiletype dockerfile
	autocmd FileType dockerfile setlocal expandtab
	autocmd FileType dockerfile setlocal tabstop=4
	autocmd FileType dockerfile setlocal shiftwidth=4
	autocmd FileType dockerfile setlocal softtabstop=4
augroup END


" ==========================================
" 10. 파일 끝 빈 줄 설정
" ==========================================
set fixendofline              " 파일 끝에 newline 추가
set endofline                 " 파일이 newline으로 끝나도록


" ==========================================
" 11. Trailing Whitespace 하이라이트
" ==========================================
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

augroup HighlightTrailing
	autocmd!
	autocmd BufEnter,InsertLeave * match ExtraWhitespace /\s\+$/
	autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
augroup END


" ==========================================
" 12. Keymaps
" ==========================================
" <leader>tw : 줄 끝 공백 제거
nnoremap <silent> <leader>tw :%s/\s\+$//e<CR>

" <leader>rt : 탭을 공백으로 변환 (Python 등)
nnoremap <silent> <leader>rt :retab<CR>

" <leader>ff : 파일 포맷 Unix로 변환
nnoremap <silent> <leader>ff :set fileformat=unix<CR>


" ==========================================
" 13. 로컬 설정 안내
" ==========================================
" 이 파일을 프로젝트에서 자동으로 로드하려면
" ~/.vimrc 또는 ~/.vim/vimrc에 다음을 추가:
"
" " Load project-local .vimrc if it exists
" set exrc
" set secure
"
" 또는 특정 프로젝트 경로에만 적용:
" autocmd BufRead,BufNewFile ~/project-iamwonseok/agent-context/*
"     \ source ~/project-iamwonseok/agent-context/.vimrc
