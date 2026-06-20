#!/usr/bin/env bash
# =============================================================================
# des.sh
# 개발환경 자동 설치 스크립트
#
# 지원 언어 : C, C++, Python3, Rust, Bash
# 주요 기능 : caller/callee 추적, go-to-definition, references, 자동완성
# 지원 OS   : Ubuntu 22.04 (Jammy), Ubuntu 24.04 (Noble)
#
# 사용법    : bash des.sh
# =============================================================================

set -euo pipefail

# ─── 전역 상수 ────────────────────────────────────────────────────────────────
readonly LOG_PREFIX="[des]"
readonly VIMRC="$HOME/.vimrc"
readonly PLUG_PATH="$HOME/.vim/autoload/plug.vim"
readonly SUPPORTED_OS=("jammy" "noble")

# ─── 공통 유틸 ────────────────────────────────────────────────────────────────

# @brief 정보 메시지 출력
# @param $1 출력할 메시지
log_info() {
    echo "$LOG_PREFIX [INFO] $1"
}

# @brief 경고 메시지 출력
# @param $1 출력할 메시지
log_warn() {
    echo "$LOG_PREFIX [WARN] $1" >&2
}

# @brief 에러 메시지 출력 후 종료
# @param $1 출력할 메시지
log_error() {
    echo "$LOG_PREFIX [ERROR] $1" >&2
    exit 1
}

# @brief 단계 구분선과 함께 단계 이름 출력
# @param $1 단계 번호
# @param $2 단계 설명
print_phase() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Phase $1 : $2"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ─── OS 감지 및 검증 ──────────────────────────────────────────────────────────

# @brief 현재 OS 정보를 감지하여 전역 변수에 저장
# @sets  OS_ID       (예: ubuntu)
# @sets  OS_VERSION  (예: 24.04)
# @sets  OS_CODENAME (예: noble)
detect_os() {
    if [ ! -f /etc/os-release ]; then
        log_error "/etc/os-release 파일이 없습니다. 지원하지 않는 OS입니다."
    fi

    # shellcheck source=/dev/null
    source /etc/os-release

    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-unknown}"
    OS_CODENAME="${VERSION_CODENAME:-unknown}"

    log_info "감지된 OS : $OS_ID $OS_VERSION ($OS_CODENAME)"
}

# @brief OS가 지원 목록에 있는지 검증
# @note  ubuntu 이외의 OS, 또는 지원하지 않는 버전이면 에러 종료
verify_os_support() {
    if [ "$OS_ID" != "ubuntu" ]; then
        log_error "지원하지 않는 OS입니다: $OS_ID (Ubuntu만 지원)"
    fi

    local supported=false
    for codename in "${SUPPORTED_OS[@]}"; do
        if [ "$OS_CODENAME" = "$codename" ]; then
            supported=true
            break
        fi
    done

    if [ "$supported" = false ]; then
        log_error "지원하지 않는 Ubuntu 버전: $OS_VERSION ($OS_CODENAME) / 지원 버전: 22.04, 24.04"
    fi

    log_info "OS 검증 통과: Ubuntu $OS_VERSION ($OS_CODENAME)"
}

# ─── 공통 시스템 패키지 ───────────────────────────────────────────────────────

# @brief 모든 OS 공통으로 필요한 시스템 패키지 설치
# @note  OS별 차이가 없는 패키지만 여기에 넣음
install_common_packages() {
    log_info "공통 패키지 설치 중..."
    sudo apt-get update -qq
    sudo apt-get install -y \
        vim \
        git \
        curl \
        wget \
        build-essential \
        cmake \
        bear \
        clang \
        python3 \
        python3-pip \
        python3-venv \
        ninja-build
    log_info "공통 패키지 설치 완료"
}

# ─── OS별 전용 패키지 ─────────────────────────────────────────────────────────

# @brief Ubuntu 22.04 (Jammy) 전용 패키지 설치
# @note  clangd-15, nodejs 18.x 사용
#        apt에 rust-analyzer 없을 수 있어 rustup 우선 시도
install_system_packages_jammy() {
    log_info "[22.04 Jammy] clangd-15 설치..."
    sudo apt-get install -y clangd-15
    sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-15 100

    log_info "[22.04 Jammy] nodejs 18.x 설치..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs

    log_info "[22.04 Jammy] rust-analyzer 설치..."
    if command -v rustup &>/dev/null; then
        rustup component add rust-analyzer 2>/dev/null \
            && log_info "rustup으로 rust-analyzer 설치 완료" \
            || log_warn "rustup rust-analyzer 설치 실패, apt 시도"
    fi
    sudo apt-get install -y rust-analyzer 2>/dev/null \
        || log_warn "rust-analyzer apt 설치 실패 (rustup 사용 중이라면 무시)"
}

# @brief Ubuntu 24.04 (Noble) 전용 패키지 설치
# @note  clangd 메타패키지, nodejs 22.x 사용
install_system_packages_noble() {
    log_info "[24.04 Noble] clangd 설치..."
    sudo apt-get install -y clangd

    log_info "[24.04 Noble] nodejs 22.x 설치..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs

    log_info "[24.04 Noble] rust-analyzer 설치..."
    if command -v rustup &>/dev/null; then
        rustup component add rust-analyzer 2>/dev/null \
            && log_info "rustup으로 rust-analyzer 설치 완료" \
            || log_warn "rustup rust-analyzer 설치 실패, apt 시도"
    fi
    sudo apt-get install -y rust-analyzer 2>/dev/null \
        || log_warn "rust-analyzer apt 설치 실패 (rustup 사용 중이라면 무시)"
}

# @brief OS 코드네임에 따라 전용 패키지 설치 함수로 분기
# @note  OS별 분기의 단일 진입점
dispatch_os_packages() {
    case "$OS_CODENAME" in
        jammy)
            # ── Ubuntu 22.04 분기 ─────────────────────────────
            install_system_packages_jammy
            ;;
        noble)
            # ── Ubuntu 24.04 분기 ─────────────────────────────
            install_system_packages_noble
            ;;
        *)
            log_error "dispatch_os_packages: 알 수 없는 코드네임 $OS_CODENAME"
            ;;
    esac
}

# ─── Language Server 설치 ────────────────────────────────────────────────────

# @brief Python LSP 서버 (pylsp) 설치
# @note  22.04는 pip 직접 설치, 24.04는 apt 우선 후 pip fallback
install_pylsp() {
    log_info "pylsp (Python LSP) 설치 중..."
    case "$OS_CODENAME" in
        jammy)
            # ── Ubuntu 22.04 분기 ─────────────────────────────
            pip3 install --user --quiet python-lsp-server 2>/dev/null || true
            ;;
        noble)
            # ── Ubuntu 24.04 분기 ─────────────────────────────
            # PEP 668 적용으로 apt 우선, 없으면 --break-system-packages
            sudo apt-get install -y python3-pylsp 2>/dev/null \
                || pip3 install --user --break-system-packages --quiet \
                       python-lsp-server 2>/dev/null \
                || true
            ;;
    esac
    log_info "pylsp 설치 완료"
}

# @brief bash-language-server 설치 (npm 글로벌)
# @note  이미 설치되어 있으면 스킵
install_bash_lsp() {
    log_info "bash-language-server 설치 중..."
    if ! command -v bash-language-server &>/dev/null; then
        sudo npm install -g bash-language-server --silent
    else
        log_info "bash-language-server 이미 설치됨, 스킵"
    fi
    log_info "bash-language-server 설치 완료"
}

# @brief 전체 LSP 서버 설치 진행
# @note  clangd, rust-analyzer 는 dispatch_os_packages 에서 처리
install_lsp_servers() {
    install_pylsp
    install_bash_lsp
}

# ─── vim-plug 설치 ───────────────────────────────────────────────────────────

# @brief vim-plug 플러그인 매니저 설치
# @note  이미 설치되어 있으면 스킵
install_vim_plug() {
    log_info "vim-plug 설치 확인 중..."
    if [ ! -f "$PLUG_PATH" ]; then
        curl -sfLo "$PLUG_PATH" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        log_info "vim-plug 설치 완료"
    else
        log_info "vim-plug 이미 설치됨, 스킵"
    fi
}

# ─── .vimrc 생성 ──────────────────────────────────────────────────────────────

# @brief 기존 .vimrc 를 타임스탬프 기반 파일명으로 백업
backup_vimrc() {
    if [ -f "$VIMRC" ]; then
        local backup="${VIMRC}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$VIMRC" "$backup"
        log_info "기존 .vimrc 백업: $backup"
    fi
}

# @brief .vimrc 파일 생성
# @note  vim-plug 단일 플러그인 매니저 사용
#        포함 항목: DoxygenToolkit, vim-cpp-enhanced-highlight,
#                   C/C++ 디버그 스니펫, 색상 설정
generate_vimrc() {
    backup_vimrc
    log_info ".vimrc 생성 중..."

    cat > "$VIMRC" << 'VIMRC_EOF'
" ============================================================
"  .vimrc  --  Vim LSP 개발환경 설정
"  언어  : C / C++ / Python3 / Rust / Bash
"  핵심  : caller/callee 추적, go-to-definition, references
"  플러그인 매니저 : vim-plug
" ============================================================

" ── 기본 설정 ───────────────────────────────────────────────
set nocompatible
set number
set tabstop=2
set shiftwidth=2
set expandtab
set smartindent
set hlsearch
set noincsearch
set ignorecase
set smartcase
set backspace=indent,eol,start
set hidden
set updatetime=300
set signcolumn=yes
set encoding=utf-8
set colorcolumn=81
set scrolloff=5
set t_Co=256
set background=dark
set term=xterm
" 상대괄호 표시 제거      
let g:loaded_matchparen = 1 

syntax on
filetype plugin indent on

" ── 플러그인 ────────────────────────────────────────────────
call plug#begin('~/.vim/plugged')

" LSP 코어
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'

" LSP 자동완성
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" LSP 서버 자동 설정 보조
Plug 'mattn/vim-lsp-settings'

" 파일 탐색 (트리)
Plug 'preservim/nerdtree'

" 퍼지 파일/버퍼/텍스트 검색
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" 상태바
Plug 'vim-airline/vim-airline'

" C/C++ 향상 문법 하이라이트
Plug 'octol/vim-cpp-enhanced-highlight'

" Doxygen 주석 자동 생성
Plug 'vim-scripts/DoxygenToolkit.vim'

" 파일 구조 사이드바 (LSP 기반, Tagbar 대체)
Plug 'liuchengxu/vista.vim'

" git 변경 표시
Plug 'airblade/vim-gitgutter'

call plug#end()

" ── vim-lsp 전역 옵션 ───────────────────────────────────────
let g:lsp_diagnostics_enabled        = 0  " 진단 비활성화
let g:lsp_diagnostics_echo_cursor    = 0  " 커서 위치 진단 메시지 비활성화
let g:lsp_diagnostics_signs_enabled  = 0  " 좌측 사인컬럼 표시 비활성화
let g:lsp_document_highlight_enabled = 1  " 같은 심볼 하이라이트
let g:lsp_inlay_hints_enabled        = 0  " 인라인 파라미터 힌트 비활성화
let g:lsp_call_hierarchy_enabled     = 1  " call hierarchy 활성화
let g:lsp_format_sync_timeout        = 1000

" ── 자동완성 옵션 ───────────────────────────────────────────
set completeopt=menuone,noinsert,noselect
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_popup_delay = 50

" ── Language Server 등록 ────────────────────────────────────

" --- clangd : C / C++ ---
if executable('clangd')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'clangd',
        \ 'cmd': {server_info->['clangd',
        \     '--background-index',
        \     '--clang-tidy',
        \     '--header-insertion=never',
        \     '--completion-style=detailed',
        \     '--function-arg-placeholders']},
        \ 'allowlist': ['c', 'cpp', 'objc', 'objcpp'],
        \ })
endif

" --- pylsp : Python3 ---
if executable('pylsp')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pylsp',
        \ 'cmd': {server_info->['pylsp']},
        \ 'allowlist': ['python'],
        \ })
endif

" --- rust-analyzer : Rust ---
if executable('rust-analyzer')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'rust-analyzer',
        \ 'cmd': {server_info->['rust-analyzer']},
        \ 'allowlist': ['rust'],
        \ 'initialization_options': {
        \   'cargo': {'buildScripts': {'enable': v:true}},
        \   'procMacro': {'enable': v:true},
        \ }})
endif

" --- bash-language-server : Bash ---
if executable('bash-language-server')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'bash-language-server',
        \ 'cmd': {server_info->['bash-language-server', 'start']},
        \ 'allowlist': ['sh', 'bash'],
        \ })
endif

" ── LSP 버퍼 활성화 시 키맵 ────────────────────────────────
function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif

    " 정의 / 선언 / 타입 / 구현으로 이동
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> gD <plug>(lsp-declaration)
    nmap <buffer> gy <plug>(lsp-type-definition)
    nmap <buffer> gi <plug>(lsp-implementation)

    " 참조 전체 찾기
    nmap <buffer> gr <plug>(lsp-references)

    " ★ Caller 추적 : 이 함수를 호출하는 곳 목록
    nmap <buffer> <Leader>ci <plug>(lsp-call-hierarchy-incoming)

    " ★ Callee 추적 : 이 함수가 호출하는 함수 목록
    nmap <buffer> <Leader>co <plug>(lsp-call-hierarchy-outgoing)

    " 심볼 정보 호버
    nmap <buffer> K <plug>(lsp-hover)

    " 이름 변경 (리팩터링)
    nmap <buffer> <Leader>rn <plug>(lsp-rename)

    " 다음 / 이전 에러로 이동
    nmap <buffer> ]e <plug>(lsp-next-error)
    nmap <buffer> [e <plug>(lsp-previous-error)

    " 진단 목록
    nmap <buffer> <Leader>e <plug>(lsp-document-diagnostics)

    " 현재 파일 심볼 검색
    nmap <buffer> <Leader>s <plug>(lsp-document-symbol-search)

    " 프로젝트 전체 심볼 검색
    nmap <buffer> <Leader>S <plug>(lsp-workspace-symbol-search)

    " 코드 자동 수정 제안
    nmap <buffer> <Leader>ca <plug>(lsp-code-action)

    " 파일 포맷
    nmap <buffer> <Leader>f <plug>(lsp-document-format)
endfunction

augroup lsp_install
    au!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" ── 자동완성 Tab 키 ─────────────────────────────────────────
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>    pumvisible() ? asyncomplete#close_popup() : "\<CR>"

" ── Leader 키 ───────────────────────────────────────────────
let mapleader = " "

" ── NERDTree ────────────────────────────────────────────────
let NERDTreeWinSize  = 40
let NERDTreeWinPos   = "right"
let g:NERDTreeShowHidden = 1
nmap <F4>  :NERDTreeToggle<CR>
nmap ;4    :NERDTreeToggle<CR>

" ── Vista (파일 구조 사이드바) ───────────────────────────────
" LSP 백엔드 사용 (vim-lsp 연동)
let g:vista_default_executive = 'vim_lsp'
" 파일 타입별 백엔드 지정 (LSP 없는 경우 ctags fallback)
let g:vista_executive_for = {
    \ 'c':      'vim_lsp',
    \ 'cpp':    'vim_lsp',
    \ 'python': 'vim_lsp',
    \ 'rust':   'vim_lsp',
    \ 'sh':     'vim_lsp',
    \ }
" 좌측 배치
let g:vista_sidebar_position = 'vertical topleft'
" 폭: 전체 폭의 20%
let g:vista_sidebar_width = float2nr(&columns * 0.20)
" 커서 미리보기 끄기
let g:vista_echo_cursor = 0
" F3 토글
nmap <F3> :Vista!!<CR>
" ;3 토글 (;키 누르고 3키)
nmap ;3   :Vista!!<CR>

" ── fzf ─────────────────────────────────────────────────────
nmap <Leader>p :Files<CR>
nmap <Leader>b :Buffers<CR>
nmap <Leader>/ :Rg<CR>
" F2 / ;2 : 버퍼 목록 (BufExplorer 대체)
nmap <F2> :Buffers<CR>
nmap ;2   :Buffers<CR>

" ── 창 이동 ─────────────────────────────────────────────────
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k

" ── 버퍼 이동 ───────────────────────────────────────────────
nmap <Tab>   :bnext<CR>
nmap <S-Tab> :bprev<CR>

" ── 검색 하이라이트 끄기 ────────────────────────────────────
nmap <Leader><Space> :nohl<CR>

" ── C/C++ 디버그 출력 스니펫 ────────────────────────────────
nmap [2 <Insert>printf("\033[1;33m[%s][%d] :chk: \033[m\n",__FUNCTION__,__LINE__);<CR><C-C>
" [3 : 하늘색 printf 삽입
nmap [3 <Insert>printf("\033[1;36m[%s][%d] :chk: \033[m\n",__FUNCTION__,__LINE__);<CR><C-C>

" ── 색상 설정 ───────────────────────────────────────────────
colorscheme desert
hi Comment  term=NONE  ctermfg=white  gui=bold
hi Function term=bold  ctermfg=Green  gui=bold
hi String   term=bold  ctermfg=Blue   gui=bold
hi Number   term=NONE  ctermfg=Gray
highlight Pmenu ctermfg=14 ctermbg=0

" ── Python 들여쓰기 ─────────────────────────────────────────
autocmd FileType python set shiftwidth=2 tabstop=2 expandtab

VIMRC_EOF

    log_info ".vimrc 생성 완료: $VIMRC"
}

# ─── .tmux.conf 생성 ─────────────────────────────────────────────────────────

# @brief 기존 .tmux.conf 를 타임스탬프 기반 파일명으로 백업
backup_tmux_conf() {
    local tmux_conf="$HOME/.tmux.conf"
    if [ -f "$tmux_conf" ]; then
        local backup="${tmux_conf}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$tmux_conf" "$backup"
        log_info "기존 .tmux.conf 백업: $backup"
    fi
}

# @brief .tmux.conf 파일 생성
# @note  256color, vi 키바인딩, 스크롤백 100000줄,
#        창 분할 시 현재 경로 유지, pane 리사이즈 키 포함
generate_tmux_conf() {
    backup_tmux_conf
    log_info ".tmux.conf 생성 중..."

    cat > "$HOME/.tmux.conf" << 'TMUX_EOF'
# ============================================================
#  .tmux.conf
# ============================================================

# 256color 터미널
set -g default-terminal "screen-256color"

# vi 키바인딩 (copy mode)
setw -g mode-keys vi

# 스크롤백 버퍼 100000줄
set -g history-limit 100000

# 창 번호 1부터 시작
set -g base-index 0 

# 마우스 활성화
set -g mouse off

# 상태바 갱신 주기 (초)
set -g status-interval 5

# ── 창 분할 : 현재 경로 유지 ────────────────────────────────
bind '"' split-window    -c "#{pane_current_path}"
bind '%' split-window -h -c "#{pane_current_path}"
bind 'c' new-window      -c "#{pane_current_path}"

# ── pane 리사이즈 ───────────────────────────────────────────
bind k resize-pane -R 5
bind j resize-pane -L 5
bind i resize-pane -U 5
bind m resize-pane -D 5

# ── pane 이동 (vim 방향키) ───────────────────────────────────
bind h select-pane -L
bind l select-pane -R
bind Up    select-pane -U
bind Down  select-pane -D

TMUX_EOF

    log_info ".tmux.conf 생성 완료: $HOME/.tmux.conf"
}

# ─── git config 생성 ──────────────────────────────────────────────────────────

# @brief 기존 .gitconfig 를 타임스탬프 기반 파일명으로 백업
backup_gitconfig() {
    local gitconfig="$HOME/.gitconfig"
    if [ -f "$gitconfig" ]; then
        local backup="${gitconfig}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$gitconfig" "$backup"
        log_info "기존 .gitconfig 백업: $backup"
    fi
}

# @brief ~/.gitconfig 틀 생성
# @note  user.name, user.email 은 플레이스홀더로 두고 직접 수정하도록 안내
#        diff/merge tool: vimdiff, editor: vim
generate_gitconfig() {
    backup_gitconfig
    log_info ".gitconfig 생성 중..."

    cat > "$HOME/.gitconfig" << 'GITCONFIG_EOF'
# ============================================================
#  ~/.gitconfig
#  주의: user.name 과 user.email 을 직접 수정하세요.
# ============================================================

[user]
    name  = YOUR_NAME
    email = YOUR_EMAIL

[core]
    editor = vim

[push]
    default = matching

[diff]
    tool = vimdiff

[merge]
    tool = vimdiff
    conflictstyle = diff3

[difftool]
    prompt = false

[mergetool]
    prompt = false

GITCONFIG_EOF

    log_info ".gitconfig 생성 완료: $HOME/.gitconfig"
    log_warn "user.name 과 user.email 을 직접 수정하세요: $HOME/.gitconfig"
}

# ─── vim 플러그인 설치 ────────────────────────────────────────────────────────

# @brief vim PlugInstall 을 터미널 모드로 실행
# @note  진행상황이 터미널에 직접 출력됨
run_plug_install() {
    log_info "vim 플러그인 설치 중 (PlugInstall)..."
    vim -u "$VIMRC" +PlugInstall +qall
    log_info "플러그인 설치 완료"
}

# ─── 완료 메시지 ──────────────────────────────────────────────────────────────

# @brief 설치 완료 후 단축키 사용법 요약 출력
print_usage_summary() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║              설치 완료                           ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    echo "Leader 키 = Space"
    echo ""
    echo "── 이동 ───────────────────────────────────────────"
    echo "  gd           정의로 이동"
    echo "  gi           구현으로 이동"
    echo "  gr           참조 전체 찾기"
    echo "  K            심볼 정보 호버"
    echo ""
    echo "── ★ Caller / Callee 추적 ─────────────────────────"
    echo "  Space+ci     이 함수를 호출하는 곳 (Caller)"
    echo "  Space+co     이 함수가 호출하는 함수들 (Callee)"
    echo ""
    echo "── 버퍼/파일 ──────────────────────────────────────"
    echo "  F2 또는 ;2   버퍼 목록 (fzf, BufExplorer 대체)"
    echo "  Space+p      파일 퍼지 검색"
    echo "  Space+/      프로젝트 전체 텍스트 검색 (rg)"
    echo "  Space+s      현재 파일 심볼 검색"
    echo "  Space+S      프로젝트 심볼 검색"
    echo ""
    echo "── 편집 ───────────────────────────────────────────"
    echo "  Space+rn     심볼 이름 변경"
    echo "  Space+ca     코드 자동 수정"
    echo "  Space+f      파일 포맷"
    echo "  F4 또는 ;4   NERDTree 토글 (우측, 폭 40)"
    echo ""
    echo "── Vista (파일 구조 사이드바) ──────────────────────"
    echo "  F3 또는 ;3   Vista 토글 (좌측, 폭 20%)"
    echo ""
    echo "── C/C++ 디버그 스니펫 ─────────────────────────────"
    echo "  [2           노란색 printf 삽입"
    echo "  [3           하늘색 printf 삽입"
    echo ""
    echo "── 생성된 설정 파일 ───────────────────────────────"
    echo "  ~/.vimrc       Vim 설정"
    echo "  ~/.tmux.conf   tmux 설정"
    echo "  ~/.gitconfig   git 설정 (user.name/email 직접 수정 필요)"
    echo ""
    echo "── C/C++ 주의사항 ─────────────────────────────────"
    echo "  clangd는 compile_commands.json 이 필요합니다."
    echo "  CMake : cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ."
    echo "  Make  : bear -- make"
    echo ""
}

# ─── main ─────────────────────────────────────────────────────────────────────

# @brief 스크립트 진입점
# @note  순서: OS감지 -> 검증 -> 공통패키지 -> OS별패키지
#              -> LSP서버 -> vim-plug -> vimrc -> 플러그인설치
main() {
    local start_time
    start_time=$(date +%s)

    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  Vim LSP Setup                                   ║"
    echo "║  C / C++ / Python3 / Rust / Bash                 ║"
    echo "╚══════════════════════════════════════════════════╝"

    # ── sudo 인증 (최초 1회) ────────────────────────────────
    echo ""
    echo "sudo 권한이 필요합니다. 패스워드를 입력해주세요."
    sudo -v || log_error "sudo 인증 실패"
    log_info "sudo 인증 완료"

    # sudo 캐시 갱신 (백그라운드, 설치 완료 시 종료)
    # @note  기본 sudo 캐시 유효시간(15분) 초과 방지
    ( while true; do sudo -v; sleep 60; done ) &
    local SUDO_REFRESH_PID=$!
    trap "kill $SUDO_REFRESH_PID 2>/dev/null" EXIT

    print_phase 1 "OS 감지 및 검증"
    detect_os
    verify_os_support

    print_phase 2 "공통 시스템 패키지 설치"
    install_common_packages

    print_phase 3 "OS별 전용 패키지 설치 [OS: $OS_CODENAME]"
    dispatch_os_packages

    print_phase 4 "Language Server 설치"
    install_lsp_servers

    print_phase 5 "vim-plug 설치"
    install_vim_plug

    print_phase 6 ".vimrc 생성"
    generate_vimrc

    print_phase 7 "Vim 플러그인 설치"
    run_plug_install

    print_phase 8 ".tmux.conf 생성"
    generate_tmux_conf

    print_phase 9 ".gitconfig 틀 생성"
    generate_gitconfig

    local end_time elapsed
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))

    print_usage_summary

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  총 설치 시간 : ${minutes}분 ${seconds}초"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

main "$@"
