Windheim's Development Environment Settings
========

This tool is for settings of development environment. 
You can down load this tool without cloning.

### 1. Vim Setup (`des.sh`)

```bash
wget https://raw.githubusercontent.com/githeim/wh_dev/ubuntu_24_04/des.sh
bash des.sh
```

The following features are applied. Development environment is based on vim.

* Languages  : C / C++ / Python3 / Rust / Bash
* Features  : LSP Support ;  caller/callee trace, go-to-definition, references
* plugin manager : vim-plug

### 2. Neovim Setup (`des_nvim.sh`)

```bash
wget https://raw.githubusercontent.com/githeim/wh_dev/ubuntu_24_04/des_nvim.sh
bash des_nvim.sh
```

The following features are applied. Development environment is based on Neovim (latest official release, linked to `vi` / `vim` / `nvim`).

* Languages  : C / C++ / Python3 / Rust / Bash (Supported OS: Ubuntu 22.04 / 24.04 / 26.04)
* Features  : Built-in Native LSP (`vim.lsp`) & Tree-sitter ; caller/callee trace, go-to-definition, references
* plugin manager : lazy.nvim (`fzf-lua`, `aerial.nvim`, `nvim-tree.lua`, `DoxygenToolkit.vim`, `gitsigns.nvim`)
