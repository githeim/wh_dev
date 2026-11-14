#!/usr/bin/env bash
# =============================================================================
# des_nvim.sh
# Neovim 개발환경 자동 설치 스크립트
#
# 지원 언어 : C, C++, Python3, Rust, Bash
# 주요 기능 : 내장 LSP(vim.lsp), Tree-sitter, caller/callee 추적, go-to-definition, references, 자동완성
# 지원 OS   : Ubuntu 22.04 (Jammy), Ubuntu 24.04 (Noble), Ubuntu 26.04 (Resolute)
#
# 사용법    : bash des_nvim.sh
# =============================================================================

set -euo pipefail

# ─── 전역 상수 ────────────────────────────────────────────────────────────────
readonly LOG_PREFIX="[des_nvim]"
readonly NVIM_CONFIG_DIR="$HOME/.config/nvim"
readonly INIT_LUA="$NVIM_CONFIG_DIR/init.lua"
readonly SUPPORTED_OS=("jammy" "noble" "resolute")

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
        log_error "지원하지 않는 Ubuntu 버전: $OS_VERSION ($OS_CODENAME) / 지원 버전: 22.04, 24.04, 26.04"
    fi

    log_info "OS 검증 통과: Ubuntu $OS_VERSION ($OS_CODENAME)"
}

# ─── 공통 시스템 패키지 ───────────────────────────────────────────────────────

# @brief 모든 OS 공통으로 필요한 시스템 패키지 설치
# @note  OS별 차이가 없는 패키지만 여기에 넣음 (fzf-lua용 fzf, ripgrep, fd-find 포함)
install_common_packages() {
    log_info "공통 패키지 설치 중..."
    sudo apt-get update -qq
    sudo apt-get install -y \
        git \
        curl \
        wget \
        tar \
        gzip \
        build-essential \
        cmake \
        bear \
        clang \
        python3 \
        python3-pip \
        python3-venv \
        ninja-build \
        ripgrep \
        fd-find \
        fzf \
        tmux
    log_info "공통 패키지 설치 완료"
}

# ─── Neovim 최신 버전 설치 ────────────────────────────────────────────────────

# @brief GitHub 공식 최신 릴리즈에서 Neovim 바이너리를 설치
# @note  기본값으로 vi/vim/editor 시스템 대체를 Neovim으로 변경하며,
#        DES_NVIM_SET_SYSTEM_ALTERNATIVES=0이면 변경하지 않음
# @note  x86_64 및 arm64(aarch64) 아키텍처 자동 감지, Ubuntu 22.04~26.04 호환
install_neovim_latest() {
    local arch
    arch="$(uname -m)"
    local nvim_arch
    case "$arch" in
        x86_64)  nvim_arch="x86_64" ;;
        aarch64|arm64) nvim_arch="arm64" ;;
        *) log_error "지원하지 않는 아키텍처입니다: $arch" ;;
    esac

    local tarball="nvim-linux-${nvim_arch}.tar.gz"
    local url="https://github.com/neovim/neovim/releases/latest/download/${tarball}"
    local tmp_tar="/tmp/${tarball}"
    local install_dir="/opt/nvim-linux-${nvim_arch}"

    log_info "Neovim 최신 릴리즈 다운로드 중 ($url)..."
    curl -fLo "$tmp_tar" "$url"

    log_info "/opt 에 Neovim 압축 해제 및 설치 중..."
    sudo rm -rf "$install_dir"
    sudo tar -C /opt -xzf "$tmp_tar"
    rm -f "$tmp_tar"

    if [ -e /opt/nvim ] && [ ! -L /opt/nvim ]; then
        log_error "/opt/nvim 이 심볼릭 링크가 아닙니다. 기존 디렉터리를 삭제하지 않고 중단합니다."
    fi
    sudo ln -sfn "$install_dir" /opt/nvim
    sudo ln -sfn /opt/nvim/bin/nvim /usr/local/bin/nvim

    if [ "${DES_NVIM_SET_SYSTEM_ALTERNATIVES:-1}" != "0" ]; then
        log_info "vi / vim / editor 명령어를 Neovim으로 연결 중 (기본 적용, 비활성화: DES_NVIM_SET_SYSTEM_ALTERNATIVES=0)..."
        sudo update-alternatives --install /usr/bin/vi vi /usr/local/bin/nvim 110
        sudo update-alternatives --set vi /usr/local/bin/nvim
        sudo update-alternatives --install /usr/bin/vim vim /usr/local/bin/nvim 110
        sudo update-alternatives --set vim /usr/local/bin/nvim
        sudo update-alternatives --install /usr/bin/editor editor /usr/local/bin/nvim 110
        sudo update-alternatives --set editor /usr/local/bin/nvim
    else
        log_info "vi/vim/editor 시스템 대체를 변경하지 않습니다 (DES_NVIM_SET_SYSTEM_ALTERNATIVES=0)."
    fi

    local nvim_ver
    nvim_ver="$(/usr/local/bin/nvim --version | head -n 1)"
    log_info "Neovim 설치 완료: $nvim_ver"
}

# ─── OS별 전용 패키지 ─────────────────────────────────────────────────────────

# @brief rustup으로 rust-analyzer를 설치하고 실행 가능 여부를 검증
install_rust_analyzer() {
    if command -v rust-analyzer &>/dev/null; then
        log_info "rust-analyzer 이미 설치됨: $(command -v rust-analyzer)"
        return
    fi

    log_info "rust-analyzer 설치를 위해 rustup 준비 중..."
    if ! command -v rustup &>/dev/null; then
        sudo apt-get install -y rustup
    fi

    export PATH="$HOME/.cargo/bin:$PATH"
    command -v rustup &>/dev/null || log_error "rustup 실행 파일을 찾을 수 없습니다"

    if ! rustup show active-toolchain 2>/dev/null | grep -q .; then
        rustup default stable
    fi
    rustup component add rust-src rust-analyzer

    command -v rust-analyzer &>/dev/null || log_error "rust-analyzer 설치 뒤 실행 파일을 찾을 수 없습니다"
    log_info "rust-analyzer 설치 완료: $(command -v rust-analyzer)"
}

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

    install_rust_analyzer
}

# @brief Ubuntu 24.04 (Noble) 전용 패키지 설치
# @note  clangd 메타패키지, nodejs 22.x 사용
install_system_packages_noble() {
    log_info "[24.04 Noble] clangd 설치..."
    sudo apt-get install -y clangd

    log_info "[24.04 Noble] nodejs 22.x 설치..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs

    install_rust_analyzer
}

# @brief Ubuntu 26.04 (Resolute) 전용 패키지 설치
# @note  clangd 메타패키지, Ubuntu 저장소 Node.js 22.x 사용
#        rust-analyzer는 Ubuntu 26.04 저장소에 없으므로 rustup으로 설치
install_system_packages_resolute() {
    log_info "[26.04 Resolute] clangd 설치..."
    sudo apt-get install -y clangd

    log_info "[26.04 Resolute] Ubuntu 저장소 Node.js 설치..."
    sudo apt-get install -y nodejs npm

    install_rust_analyzer
}

# @brief OS 코드네임에 따라 전용 패키지 설치 함수로 분기
# @note  OS별 분기의 단일 진입점
dispatch_os_packages() {
    case "$OS_CODENAME" in
        jammy)
            install_system_packages_jammy
            ;;
        noble)
            install_system_packages_noble
            ;;
        resolute)
            install_system_packages_resolute
            ;;
        *)
            log_error "dispatch_os_packages: 알 수 없는 코드네임 $OS_CODENAME"
            ;;
    esac
}

# ─── Language Server 설치 ────────────────────────────────────────────────────

# @brief Python LSP 서버 (pylsp) 설치
# @note  22.04는 pip 직접 설치, 24.04/26.04는 apt 우선 후 pip fallback
install_pylsp() {
    log_info "pylsp (Python LSP) 설치 중..."
    export PATH="$HOME/.local/bin:$PATH"
    case "$OS_CODENAME" in
        jammy)
            pip3 install --user --quiet python-lsp-server
            ;;
        noble|resolute)
            sudo apt-get install -y python3-pylsp \
                || pip3 install --user --break-system-packages --quiet python-lsp-server
            ;;
    esac
    command -v pylsp &>/dev/null || log_error "pylsp 설치 뒤 실행 파일을 찾을 수 없습니다"
    log_info "pylsp 설치 완료: $(command -v pylsp)"
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

# ─── init.lua 생성 ────────────────────────────────────────────────────────────

# @brief 기존 init.lua 를 타임스탬프 기반 파일명으로 백업
backup_init_lua() {
    if [ -f "$INIT_LUA" ]; then
        local backup="${INIT_LUA}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$INIT_LUA" "$backup"
        log_info "기존 init.lua 백업: $backup"
    fi
}

# @brief ~/.config/nvim/init.lua 생성
# @note  Neovim 0.11+ 순정 내장 LSP(vim.lsp.config/enable) + 내장 Tree-sitter 사용
#        최소 필수 플러그인(lazy.nvim): fzf-lua, aerial.nvim, nvim-tree.lua, DoxygenToolkit, gitsigns
generate_init_lua() {
    if [ -e "$NVIM_CONFIG_DIR" ] && [ ! -d "$NVIM_CONFIG_DIR" ]; then
        log_error "Neovim 설정 경로가 디렉터리가 아닙니다: $NVIM_CONFIG_DIR"
    fi

    # 상위 ~/.config가 root 소유여도 nvim 전용 경로만 현재 사용자 소유로 생성한다.
    sudo install -d -o "$(id -u)" -g "$(id -g)" -m 0755 "$NVIM_CONFIG_DIR"
    backup_init_lua
    log_info "init.lua 생성 중..."

    cat > "$INIT_LUA" << 'INIT_LUA_EOF'
-- ============================================================
--  ~/.config/nvim/init.lua  --  Neovim 순정 LSP 개발환경 설정
--  언어  : C / C++ / Python3 / Rust / Bash
--  핵심  : 내장 vim.lsp + Tree-sitter, caller/callee 추적, gd, gr
--  플러그인 매니저 : lazy.nvim (UI 필수 플러그인만 최소 구성)
-- ============================================================

-- ── Leader 키 (매핑보다 반드시 먼저 선언) ───────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- netrw 비활성화 (nvim-tree 사용)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- 상대괄호 하이라이트 제거
vim.g.loaded_matchparen = 1

-- ── 기본 설정 ───────────────────────────────────────────────
local opt = vim.opt
opt.number         = true
opt.tabstop        = 2
opt.shiftwidth     = 2
opt.expandtab      = true
opt.smartindent    = true
opt.hlsearch       = true
opt.incsearch      = false
opt.ignorecase     = true
opt.smartcase      = true
opt.hidden         = true
opt.updatetime     = 300
opt.signcolumn     = "yes"
opt.encoding       = "utf-8"
opt.colorcolumn    = "81"
opt.scrolloff      = 5
opt.termguicolors  = true
opt.background     = "dark"
opt.completeopt    = { "menuone", "noinsert", "noselect" }
-- 마우스 입력 비활성화: 키보드 기반 조작만 사용
opt.mouse          = ""

-- Python 포함 모든 파일 2칸 들여쓰기 강제 (기본 ftplugin 덮어쓰기 방지)
vim.g.python_recommended_style = 0
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- 내장 Tree-sitter 하이라이팅 자동 활성화
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- ── 색상 설정 (desert + 커스텀 하이라이트) ──────────────────
vim.cmd([[colorscheme desert]])
vim.cmd([[hi Comment  term=NONE  ctermfg=white  gui=bold]])
vim.cmd([[hi Function term=bold  ctermfg=Green  gui=bold]])
vim.cmd([[hi String   term=bold  ctermfg=Blue   gui=bold]])
vim.cmd([[hi Number   term=NONE  ctermfg=Gray]])
vim.cmd([[highlight Pmenu ctermfg=14 ctermbg=0]])

-- ── lazy.nvim 부트스트랩 ────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ── 최소 필수 플러그인 설정 ─────────────────────────────────
require("lazy").setup({
  -- (1) 버퍼/파일/텍스트/LSP 퍼지 탐색 (F2, Space+p, Space+/)
  {
    "ibhagwan/fzf-lua",
    opts = {
      winopts = {
        height = 0.85,
        width  = 0.85,
      },
    },
  },

  -- (2) 심볼 트리 사이드바 (F3 / ;3, 좌측 폭 20%, LSP + Tree-sitter)
  {
    "stevearc/aerial.nvim",
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        default_direction = "left",
        placement = "edge",
        width = 0.20,
      },
      attach_mode = "global",
      show_guides = true,
    },
  },

  -- (3) 파일 트리 사이드바 (F4 / ;4, 우측 폭 40, NERDTree 대체)
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      view = {
        side = "right",
        width = 40,
      },
      renderer = {
        icons = {
          show = {
            file = false,
            folder = false,
            folder_arrow = true,
            git = true,
          },
        },
      },
      filters = {
        dotfiles = false,
      },
    },
  },

  -- (4) Doxygen 주석 자동 생성 (:Dox)
  {
    "vim-scripts/DoxygenToolkit.vim",
  },

  -- (5) Git 변경 라인 표시
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },
}, {
  rocks = { enabled = false },
})

-- ── 내장 LSP 전역 옵션 (진단 활성화, 인레이 힌트 비활성화) ──
vim.diagnostic.enable(true)
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
})
if vim.lsp.inlay_hint then
  vim.lsp.inlay_hint.enable(false)
end

-- ── 내장 Language Server 등록 (외부 플러그인 없이 순정 API) ─
-- (1) clangd : C / C++
if vim.fn.executable("clangd") == 1 then
  vim.lsp.config("clangd", {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=never",
      "--completion-style=detailed",
      "--function-arg-placeholders=1",
    },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" },
  })
  vim.lsp.enable("clangd")
end

-- (2) pylsp : Python3
if vim.fn.executable("pylsp") == 1 then
  vim.lsp.config("pylsp", {
    cmd = { "pylsp" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
  })
  vim.lsp.enable("pylsp")
end

-- (3) rust_analyzer : Rust
if vim.fn.executable("rust-analyzer") == 1 then
  vim.lsp.config("rust_analyzer", {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json", ".git" },
    settings = {
      ["rust-analyzer"] = {
        cargo = { buildScripts = { enable = true } },
        procMacro = { enable = true },
      },
    },
  })
  vim.lsp.enable("rust_analyzer")
end

-- (4) bashls : Bash
if vim.fn.executable("bash-language-server") == 1 then
  vim.lsp.config("bashls", {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash" },
    root_markers = { ".git" },
  })
  vim.lsp.enable("bashls")
end

-- ── 내장 LSP 버퍼 연결 시 키맵 및 자동완성 설정 ─────────────
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local opts = { buffer = ev.buf, silent = true }

    -- 내장 LSP 자동완성 활성화 (타이핑 시 자동 팝업)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end

    -- 동일 심볼 하이라이트
    if client and client:supports_method("textDocument/documentHighlight") then
      local hl_group = vim.api.nvim_create_augroup("lsp_doc_hl_" .. ev.buf, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = hl_group,
        buffer = ev.buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = hl_group,
        buffer = ev.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end

    -- 정의 / 선언 / 타입 / 구현으로 이동
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)

    -- 참조 전체 찾기
    vim.keymap.set("n", "gr", function()
      local ok, fzf = pcall(require, "fzf-lua")
      if ok then fzf.lsp_references() else vim.lsp.buf.references() end
    end, opts)

    -- ★ Caller 추적 : 이 함수를 호출하는 곳 목록
    vim.keymap.set("n", "<Leader>ci", function()
      local ok, fzf = pcall(require, "fzf-lua")
      if ok then fzf.lsp_incoming_calls() else vim.lsp.buf.incoming_calls() end
    end, opts)

    -- ★ Callee 추적 : 이 함수가 호출하는 함수 목록
    vim.keymap.set("n", "<Leader>co", function()
      local ok, fzf = pcall(require, "fzf-lua")
      if ok then fzf.lsp_outgoing_calls() else vim.lsp.buf.outgoing_calls() end
    end, opts)

    -- 심볼 정보 호버
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

    -- 이름 변경 (리팩터링)
    vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, opts)

    -- 다음 / 이전 에러로 이동
    vim.keymap.set("n", "]e", function() vim.diagnostic.jump({ count = 1 }) end, opts)
    vim.keymap.set("n", "[e", function() vim.diagnostic.jump({ count = -1 }) end, opts)

    -- 진단 목록
    vim.keymap.set("n", "<Leader>e", vim.diagnostic.setloclist, opts)

    -- 현재 파일 심볼 검색
    vim.keymap.set("n", "<Leader>s", function()
      local ok, fzf = pcall(require, "fzf-lua")
      if ok then fzf.lsp_document_symbols() else vim.lsp.buf.document_symbol() end
    end, opts)

    -- 프로젝트 전체 심볼 검색
    vim.keymap.set("n", "<Leader>S", function()
      local ok, fzf = pcall(require, "fzf-lua")
      if ok then fzf.lsp_live_workspace_symbols() else vim.lsp.buf.workspace_symbol() end
    end, opts)

    -- 코드 자동 수정 제안
    vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, opts)

    -- 파일 포맷
    vim.keymap.set("n", "<Leader>f", function() vim.lsp.buf.format({ timeout_ms = 1000 }) end, opts)
  end,
})

-- ── 자동완성 팝업 Tab / S-Tab / Enter 키 ────────────────────
vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true })
vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })
vim.keymap.set("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })

-- ── UI 도구 단축키 ──────────────────────────────────────────
-- (1) F2 / ;2 : 버퍼 목록 및 퍼지 검색 (fzf-lua)
vim.keymap.set("n", "<F2>", "<cmd>FzfLua buffers<CR>", { silent = true })
vim.keymap.set("n", ";2",   "<cmd>FzfLua buffers<CR>", { silent = true })
vim.keymap.set("n", "<Leader>b", "<cmd>FzfLua buffers<CR>", { silent = true })
vim.keymap.set("n", "<Leader>p", "<cmd>FzfLua files<CR>", { silent = true })
vim.keymap.set("n", "<Leader>/", "<cmd>FzfLua grep_cword<CR>", { silent = true })

-- (2) F3 / ;3 : 심볼 트리 사이드바 (aerial.nvim, 좌측 20%)
vim.keymap.set("n", "<F3>", "<cmd>AerialToggle!<CR>", { silent = true })
vim.keymap.set("n", ";3",   "<cmd>AerialToggle!<CR>", { silent = true })

-- (3) F4 / ;4 : 파일 트리 사이드바 (nvim-tree.lua, 우측 폭 40)
vim.keymap.set("n", "<F4>", "<cmd>NvimTreeToggle<CR>", { silent = true })
vim.keymap.set("n", ";4",   "<cmd>NvimTreeToggle<CR>", { silent = true })

-- (4) F6 / ;6 : 왼쪽 상단 절반 터미널
local function open_left_top_term()
  local buf = vim.fn.bufnr("%")
  local half = math.floor(vim.fn.winheight(0) / 2)
  vim.cmd(half .. "split")
  vim.cmd("leftabove vertical terminal ++cols=100")
  vim.cmd("wincmd l")
  vim.cmd("buffer " .. buf)
  vim.cmd("wincmd h")
end
vim.keymap.set("n", "<F6>", open_left_top_term, { silent = true })
vim.keymap.set("n", ";6",   open_left_top_term, { silent = true })

-- ── 창 이동 / 버퍼 이동 ─────────────────────────────────────
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<Tab>",   "<cmd>bnext<CR>", { silent = true })
vim.keymap.set("n", "<S-Tab>", "<cmd>bprev<CR>", { silent = true })

-- ── 검색 하이라이트 끄기 및 LSP 재시작 ──────────────────────
local function restart_lsp()
  if vim.bo.modified then
    vim.api.nvim_err_writeln("먼저 저장하십시오: :write")
    return
  end
  vim.cmd("nohlsearch")
  vim.lsp.stop_client(vim.lsp.get_clients())
  vim.defer_fn(function()
    vim.cmd("edit")
  end, 200)
end
vim.keymap.set("n", "<Leader><Space>", restart_lsp, { silent = true })
vim.keymap.set("n", "<Leader>lr",      restart_lsp, { silent = true })

-- ── C/C++ 디버그 출력 스니펫 ────────────────────────────────
vim.keymap.set("n", "[2", 'iprintf("\\033[1;33m[%s][%d] :chk: \\033[m\\n",__FUNCTION__,__LINE__);<CR><Esc>', { noremap = true })
vim.keymap.set("n", "[3", 'iprintf("\\033[1;36m[%s][%d] :chk: \\033[m\\n",__FUNCTION__,__LINE__);<CR><Esc>', { noremap = true })
INIT_LUA_EOF

    log_info "init.lua 생성 완료: $INIT_LUA"
}

# ─── Neovim 플러그인 설치 ────────────────────────────────────────────────────

# @brief lazy.nvim 플러그인 동기화를 headless 모드로 실행
run_lazy_sync() {
    log_info "Neovim 플러그인 설치 중 (Lazy sync)..."
    nvim --headless "+Lazy! sync" +qa
    log_info "플러그인 설치 완료"
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
# @note  기존 설정은 DES_NVIM_OVERWRITE_TMUX_CONF=1일 때만 백업 후 교체
generate_tmux_conf() {
    local tmux_conf="$HOME/.tmux.conf"
    if [ -f "$tmux_conf" ] && [ "${DES_NVIM_OVERWRITE_TMUX_CONF:-0}" != "1" ]; then
        log_info "기존 .tmux.conf를 유지합니다: $tmux_conf"
        log_info "스크립트 기본 Truecolor 설정으로 교체하려면 DES_NVIM_OVERWRITE_TMUX_CONF=1 로 실행하세요."
        return
    fi

    backup_tmux_conf
    log_info ".tmux.conf 생성 중..."

    cat > "$HOME/.tmux.conf" << 'TMUX_EOF'
# ============================================================
#  .tmux.conf
# ============================================================

# Truecolor(RGB) 터미널
set -g default-terminal "tmux-256color"
set -as terminal-features ",xterm-256color:RGB"
set -as terminal-overrides ",*:Tc"

# 시스템 클립보드 연동
set -g set-clipboard on

# vi 키바인딩 (copy mode)
setw -g mode-keys vi

# 스크롤백 버퍼 100000줄
set -g history-limit 100000

# 창 번호 1부터 시작
set -g base-index 1

# 마우스 비활성화
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
# @note  기존 Git identity가 있으면 덮어쓰지 않아 커밋 identity를 보존
# @note  editor를 nvim(또는 연동된 vim)으로 설정
generate_gitconfig() {
    local gitconfig="$HOME/.gitconfig"
    if [ -f "$gitconfig" ]; then
        if git config --global --get user.name >/dev/null 2>&1 \
           || git config --global --get user.email >/dev/null 2>&1; then
            log_info "기존 Git identity가 있어 .gitconfig 생성을 건너뜁니다: $gitconfig"
            return
        fi
        backup_gitconfig
    fi

    log_info ".gitconfig 틀 생성 중..."

    cat > "$HOME/.gitconfig" << 'GITCONFIG_EOF'
# ============================================================
#  ~/.gitconfig
#  주의: user.name 과 user.email 을 직접 수정하세요.
# ============================================================

[user]
    name  = YOUR_NAME
    email = YOUR_EMAIL

[core]
    editor = nvim

[push]
    default = matching

[diff]
    tool = nvimdiff

[merge]
    tool = nvimdiff
    conflictstyle = diff3

[difftool]
    prompt = false

[mergetool]
    prompt = false

GITCONFIG_EOF

    log_info ".gitconfig 생성 완료: $HOME/.gitconfig"
    log_warn "user.name 과 user.email 을 직접 수정하세요: $HOME/.gitconfig"
}

# ─── 완료 메시지 ──────────────────────────────────────────────────────────────

# @brief 설치 완료 후 단축키 사용법 요약 출력
print_usage_summary() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║              Neovim 설치 완료                    ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    echo "실행 명령어 : nvim (기본적으로 vi/vim/editor도 Neovim으로 연결, 비활성화: DES_NVIM_SET_SYSTEM_ALTERNATIVES=0)"
    echo "Leader 키   : Space"
    echo ""
    echo "── 이동 (내장 vim.lsp) ─────────────────────────────"
    echo "  gd           정의로 이동"
    echo "  gi           구현으로 이동"
    echo "  gr           참조 전체 찾기 (fzf-lua)"
    echo "  K            심볼 정보 호버"
    echo ""
    echo "── ★ Caller / Callee 추적 ─────────────────────────"
    echo "  Space+ci     이 함수를 호출하는 곳 (Caller)"
    echo "  Space+co     이 함수가 호출하는 함수들 (Callee)"
    echo ""
    echo "── 버퍼/파일 탐색 (fzf-lua) ────────────────────────"
    echo "  F2 또는 ;2   버퍼 목록"
    echo "  Space+p      파일 퍼지 검색"
    echo "  Space+/      프로젝트 전체 텍스트 검색 (rg)"
    echo "  Space+s      현재 파일 심볼 검색"
    echo "  Space+S      프로젝트 심볼 검색"
    echo ""
    echo "── 사이드바 (심볼 트리 / 파일 트리) ────────────────"
    echo "  F3 또는 ;3   Aerial 심볼 트리 토글 (좌측, 폭 20%)"
    echo "  F4 또는 ;4   nvim-tree 파일 트리 토글 (우측, 폭 40)"
    echo "  F6 또는 ;6   좌측 상단 절반 터미널 열기"
    echo ""
    echo "── 편집 ───────────────────────────────────────────"
    echo "  Space+rn     심볼 이름 변경"
    echo "  Space+ca     코드 자동 수정"
    echo "  Space+f      파일 포맷"
    echo "  Space+lr     LSP(clangd 등) 재시작"
    echo "  :Dox         Doxygen 주석 생성"
    echo ""
    echo "── C/C++ 디버그 스니펫 ─────────────────────────────"
    echo "  [2           노란색 printf 삽입"
    echo "  [3           하늘색 printf 삽입"
    echo ""
    echo "── 생성된 설정 파일 ───────────────────────────────"
    echo "  ~/.config/nvim/init.lua   Neovim 설정"
    echo "  ~/.tmux.conf              tmux 설정"
    echo "  ~/.gitconfig              git 설정 (user.name/email 직접 수정 필요)"
    echo ""
    echo "── C/C++ 주의사항 ─────────────────────────────────"
    echo "  clangd는 compile_commands.json 이 필요합니다."
    echo "  CMake : cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ."
    echo "  Make  : bear -- make"
    echo ""
}

# ─── main ─────────────────────────────────────────────────────────────────────

# @brief 스크립트 진입점
main() {
    local start_time
    start_time=$(date +%s)

    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  Neovim Native LSP Setup                         ║"
    echo "║  C / C++ / Python3 / Rust / Bash                 ║"
    echo "╚══════════════════════════════════════════════════╝"

    # ── sudo 인증 (최초 1회) ────────────────────────────────
    echo ""
    echo "sudo 권한이 필요합니다. 패스워드를 입력해주세요."
    sudo -v || log_error "sudo 인증 실패"
    log_info "sudo 인증 완료"

    # sudo 캐시 갱신 (백그라운드, 설치 완료 시 종료)
    ( while true; do sudo -v; sleep 60; done ) &
    local SUDO_REFRESH_PID=$!
    trap "kill $SUDO_REFRESH_PID 2>/dev/null" EXIT

    print_phase 1 "OS 감지 및 검증"
    detect_os
    verify_os_support

    print_phase 2 "공통 시스템 패키지 설치"
    install_common_packages

    print_phase 3 "Neovim 최신 버전 설치"
    install_neovim_latest

    print_phase 4 "OS별 전용 패키지 설치 [OS: $OS_CODENAME]"
    dispatch_os_packages

    print_phase 5 "Language Server 설치"
    install_lsp_servers

    print_phase 6 "~/.config/nvim/init.lua 생성"
    generate_init_lua

    print_phase 7 "Neovim 플러그인 설치 (lazy.nvim)"
    run_lazy_sync

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
