#!/usr/bin/python3
import subprocess
import os
import os.path
import unittest
#prerequisite
# wget
# git 
# unzip
# vim 
# gnu global 
#  
g_strPrerequisites = """sudo apt-get install build-essential cmake python-dev libncurses5-dev unzip git wget exuberant-ctags clang-8 libclang-8-dev llvm-8-dev rapidjson-dev nodejs yarn \ncurl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"""

g_strHOME= os.environ['HOME']
g_strMYBIN = g_strHOME+'/my_bin'
g_strVIM_SETTING=g_strHOME+'/.vim'


g_strBASHRC_filename=g_strHOME+'/.bashrc'
g_strBashrc_script = """
# _:x:_ Add Script for the dev. environment
export PATH+=:$HOME/my_bin:$HOME/my_bin/global/bin
export MWPATH=$HOME/work/TEST_PRJ
export MWPATH_ROOT=$MWPATH
alias ls='ls -hF --color=tty'    # classify Files in colour
alias vi='vim'
export LS_COLORS='di=01;94' # 짙은 파랑으로 나오는 디렉토리 표시를 밝은 파랑으로
export GTAGSROOT=$MWPATH
export GTAGSDBPATH=$MWPATH
#tmux 설정
alias tmux="TERM=screen-256color-bce tmux -2"    
# for git support
alias mc=". /usr/share/mc/bin/mc-wrapper.sh"                                     
git config --global user.email "nowhere@nowhere.com"                               
git config --global user.name "nowhere"                                        
git config --global push.default matching                                        
git config --global diff.tool vimdiff
git config --global  merge.tool vimdiff
git config --global  merge.conflictstyle diff3
export GIT_EDITOR=vim                                                            
export EDITOR=vim            

# :x: for remote connection
export DISPLAY=:1

# for docker
alias docker='sudo docker'           


            """
g_strBashrc_writemode ='a' # :x: add the script in the end of .bashrc file

g_strCocSettings_filename=g_strHOME+'/.vim/coc-settings.json'
g_strCocSettings_script = """
{
  "languageserver": {
    "ccls": {
      "command": "ccls",
      "filetypes": ["c", "cpp", "objc", "objcpp"],
      "rootPatterns": [".ccls", "compile_commands.json", ".vim/", ".git/", ".hg/"],
      "initializationOptions": {
        "cache": {
          "directory": "/tmp/ccls"
        }
      }
    },
    "python": {
      "command": "python",
      "args": [
        "-mpyls",
        "-vv",
        "--log-file",
        "/tmp/lsp_python.log"
      ],
      "trace.server": "verbose",
      "filetypes": [
        "python"
      ],
      "settings": {
        "pyls": {
          "enable": true,
          "trace": {
            "server": "verbose"
          },
          "commandPath": "",
          "configurationSources": [
            "pycodestyle"
          ],
          "plugins": {
            "jedi_completion": {
              "enabled": true
            },
            "jedi_hover": {
              "enabled": true
            },
            "jedi_references": {
              "enabled": true
            },
            "jedi_signature_help": {
              "enabled": true
            },
            "jedi_symbols": {
              "enabled": true,
              "all_scopes": true
            },
            "mccabe": {
              "enabled": true,
              "threshold": 15
            },
            "preload": {
              "enabled": true
            },
            "pycodestyle": {
              "enabled": true
            },
            "pydocstyle": {
              "enabled": false,
              "match": "(?!test_).*\\\\.py",
              "matchDir": "[^\\\\.].*"
            },
            "pyflakes": {
              "enabled": true
            },
            "rope_completion": {
              "enabled": true
            },
            "yapf": {
              "enabled": true
            }
          }
        }
      }
    }
  }
}
            """
g_strCocSettings_writemode ='w' # :x: write new script 

g_strCCLS_Setting_filename=g_strHOME+'/.ccls'
g_strCCLS_Setting_script = """
%c -std=c11
%cpp -std=gnu++14
%h -x
%h c++-header

# for QT support
-I/usr/include/x86_64-linux-gnu/qt5
-I/usr/include/x86_64-linux-gnu/qt5/QtCore
-I/usr/include/x86_64-linux-gnu/qt5/QtWidgets
            """
g_strCCLS_Setting_writemode ='w' # :x: add the script in the end of .bashrc file




g_strMW_filename=g_strMYBIN+'/mw'
g_strMW_script= """
# _:x:_ Add Script for the dev. environment
echo "Now MW_PATH is " $PWD
awk -F= '{if ($1 ~/export MWPATH$/) {"echo $PWD"|getline curr_dir ;  print $1"=" curr_dir; }  else { print $0;}  }' ~/.bashrc > ~/.tmpoutput
cp ~/.tmpoutput ~/.bashrc
rm ~/.tmpoutput
source ~/.bashrc
echo "Make GTAGS"
cd $MWPATH && gtags && cd -
echo "Make GTAGS Done"

"""
g_strMW_writemode ='w' # :x: write new script for mw file

g_strMdb_files_filename =g_strMYBIN+'/_mdb_files.sh'
g_strMdb_files_script ="""
#!/bin/sh
find ${MWPATH}/ -name '*.[ch]' -o -name '*.cpp' -o -name '*.cc' -not -name '.svn' > ${MWPATH}/tmp_db_files.out
mv ${MWPATH}/tmp_db_files.out ${MWPATH}/db_files.out
"""
g_strMdb_files_writemode='w'

g_strMdb_main_ctags_filename =g_strMYBIN+'/_mdb_main_ctags.sh'
g_strMdb_main_ctags_script ="""
#!/bin/sh
_TMP_DB_FILES_NAME=tmp_db_ctags_`date '+%0k_%0M_%0S_%0N'`.out
_MY_CTAGS_PATH=~/my_bin
ctags --fields=+l -f ${_MY_CTAGS_PATH}/${_TMP_DB_FILES_NAME}  -R /usr/include
mv ${_MY_CTAGS_PATH}/${_TMP_DB_FILES_NAME} ${_MY_CTAGS_PATH}/local_main_tags
"""
g_strMdb_main_ctags_writemode='w'

g_strMdb_ctags_filename =g_strMYBIN+'/_mdb_ctags.sh'
g_strMdb_ctags_script ="""
#!/bin/sh
_TMP_DB_FILES_NAME=tmp_db_ctags_`date '+%0k_%0M_%0S_%0N'`.out
ctags --fields=+l -L ${MWPATH}/db_files.out -f ${MWPATH}/${_TMP_DB_FILES_NAME} -b
mv ${MWPATH}/${_TMP_DB_FILES_NAME} ${MWPATH}/tags
"""
g_strMdb_ctags_writemode='w'

# YCM(YouCompleteMe) plugin용 configuration
g_strYCM_conf_filename=g_strHOME+"/.vim/.ycm_extra_conf.py"
g_strYCM_conf_script="""
# Copyright (C) 2014 Google Inc.
#
# This file is part of ycmd.
#
# ycmd is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ycmd is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ycmd.  If not, see <http://www.gnu.org/licenses/>.

import os
import ycm_core

# :x: my setting ###############
def GetMWPATH():
    addFlags=[]
    for (path,dir,files) in os.walk(os.environ['MWPATH'],True,None,True):
        if path.find('.git') == -1 :
            addFlags= addFlags + ['-isystem']
            addFlags= addFlags + [path]
    return addFlags
# :x: my setting end ###########



# These are the compilation flags that will be used in case there's no
# compilation database set (by default, one is not set).
# CHANGE THIS LIST OF FLAGS. YES, THIS IS THE DROID YOU HAVE BEEN LOOKING FOR.
flags = [
'-Wall',
'-Wextra',
'-Werror',
'-fexceptions',
'-DNDEBUG',
# THIS IS IMPORTANT! Without a "-std=<something>" flag, clang won't know which
# language to use when compiling headers. So it will guess. Badly. So C++
# headers will be compiled as C headers. You don't want that so ALWAYS specify
# a "-std=<something>".
# For a C project, you would set this to something like 'c99' instead of
# 'c++11'.
'-std=c++11',
# ...and the same thing goes for the magic -x option which specifies the
# language that the files to be compiled are written in. This is mostly
# relevant for c++ headers.
# For a C project, you would set this to 'c' instead of 'c++'.
'-x',
'c++',
'-isystem',
'/usr/include',
'-isystem',
'/usr/local/include',
'-isystem',
'/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/../lib/c++/v1',
'-isystem',
'/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include',

# my setting ####
'-isystem','/usr/include/SDL2',
# my setting ####

] + GetMWPATH() # :x: add path

# Set this to the absolute path to the folder (NOT the file!) containing the
# compile_commands.json file to use that instead of 'flags'. See here for
# more details: http://clang.llvm.org/docs/JSONCompilationDatabase.html
#
# Most projects will NOT need to set this to anything; you can just change the
# 'flags' list of compilation flags.
compilation_database_folder = ''

if os.path.exists( compilation_database_folder ):
  database = ycm_core.CompilationDatabase( compilation_database_folder )
else:
  database = None

SOURCE_EXTENSIONS = [ '.cpp', '.cxx', '.cc', '.c', '.m', '.mm' ]

def DirectoryOfThisScript():
  return os.path.dirname( os.path.abspath( __file__ ) )


def MakeRelativePathsInFlagsAbsolute( flags, working_directory ):
  if not working_directory:
    return list( flags )
  new_flags = []
  make_next_absolute = False
  path_flags = [ '-isystem', '-I', '-iquote', '--sysroot=' ]
  for flag in flags:
    new_flag = flag

    if make_next_absolute:
      make_next_absolute = False
      if not flag.startswith( '/' ):
        new_flag = os.path.join( working_directory, flag )

    for path_flag in path_flags:
      if flag == path_flag:
        make_next_absolute = True
        break

      if flag.startswith( path_flag ):
        path = flag[ len( path_flag ): ]
        new_flag = path_flag + os.path.join( working_directory, path )
        break

    if new_flag:
      new_flags.append( new_flag )
  return new_flags


def IsHeaderFile( filename ):
  extension = os.path.splitext( filename )[ 1 ]
  return extension in [ '.h', '.hxx', '.hpp', '.hh' ]


def GetCompilationInfoForFile( filename ):
  # The compilation_commands.json file generated by CMake does not have entries
  # for header files. So we do our best by asking the db for flags for a
  # corresponding source file, if any. If one exists, the flags for that file
  # should be good enough.
  if IsHeaderFile( filename ):
    basename = os.path.splitext( filename )[ 0 ]
    for extension in SOURCE_EXTENSIONS:
      replacement_file = basename + extension
      if os.path.exists( replacement_file ):
        compilation_info = database.GetCompilationInfoForFile(
          replacement_file )
        if compilation_info.compiler_flags_:
          return compilation_info
    return None
  return database.GetCompilationInfoForFile( filename )


# This is the entry point; this function is called by ycmd to produce flags for
# a file.
def FlagsForFile( filename, **kwargs ):
  if database:
    # Bear in mind that compilation_info.compiler_flags_ does NOT return a
    # python list, but a "list-like" StringVec object
    compilation_info = GetCompilationInfoForFile( filename )
    if not compilation_info:
      return None

    final_flags = MakeRelativePathsInFlagsAbsolute(
      compilation_info.compiler_flags_,
      compilation_info.compiler_working_dir_ )
  else:
    relative_to = DirectoryOfThisScript()
    final_flags = MakeRelativePathsInFlagsAbsolute( flags, relative_to )

  return {
    'flags': final_flags,
    'do_cache': True
  }
"""
g_strYCM_conf_writemode='w'

g_strTMUX_conf_filename=g_strHOME+"/.tmux.conf"
g_strTMUX_conf_script = """
# use vim keybindings in copy mode
setw -g mode-keys vi
 
 
# set scrollback history to 100000 (100k)
set -g history-limit 100000
bind  k resize-pane -R
bind  j resize-pane -L

bind '"' split-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"
"""
g_strTMUX_conf_writemode='w'

g_strVIMRC_filename=g_strHOME+"/.vimrc"
g_strVIMRC_script = """
set autoindent
set nu
set enc=UTF-8
set fencs=usc-bom,utf-8,euc-kr,cp949
set bs=2
"syntax 설정
syntax enable
"ctags 설정
set tags=$MWPATH/tags
set tags+=~/my_bin/local_main_tags
"tab 설정
set tabstop=2
set et
set ts=2 sw=2 sts=2
set background=dark
"마우스
"set mouse=a
"탐색결과 하이라이트
set hlsearch
"탐색시 대소문자 무시
set ignorecase
 
"Tag list 설정
let Tlist_WinWidth = 40
filetype on "이것이 없으면 Taglist동작하지 않음
"set makeprg=$MWPATH_ROOT/makefile
 
"Tag bar 설정
let g:tagbar_left = 1 "왼쪽으로 배치
 
 
"NERD tree설정
let NERDTreeWinSize = "40"
let NERDTreeWinPos ="right"
"let NERDTreeWinPos ="left"
 
"주요단축키
nmap [1 <Insert><Insert>Debug.Log(":x: chk ");<CR><C-C>
nmap [2 <Insert><Insert>printf("\\033[1;33m[%s][%d] :x: chk \\033[m\\n",__FUNCTION__,__LINE__);<CR><C-C>
nmap [3 <Insert><Insert>printf("\\033[1;36m[%s][%d] :x: chk \\033[m\\n",__FUNCTION__,__LINE__);<CR><C-C>
nmap [4 a/* :x: projectname_myname<C-R>=strftime("%Y%m%d")<CR>_*/<C-C>
nmap [5 :Gtags -r<SPACE><cword>
nmap [6 <Insert><Insert>#if 0 // :x: for test<CR>#endif // :x: for test<CR><C-C>
 
"ctags/cscope관련 단축키
nmap [7 :!~/my_bin/_mdb_files.sh &<CR><CR>
nmap [8 :!~/my_bin/_mdb_ctags.sh &<CR><CR>
nmap [0 :source ~/.vimrc<CR>:e!<CR>
nmap [- :source ~/.vimrc<CR>:UpdateTypesFileOnly<CR>
nmap [w :w<CR>:!~/my_bin/_mdb_ctags.sh &<CR><CR>
 
"gnu global 관련 단축키
nmap <C-\><C-]> :GtagsCursor<CR>


nmap <F2> :BufExplorer<CR>
"map <F3> :TlistToggle<CR>
"TagList보다 Tagbar가 좀 더 우수하다
map <F3> :TagbarToggle<CR>
map <F4> :NERDTreeToggle $PWD<CR>
map <F7> :Gtags<SPACE>
map <F8> :!bash<CR>

nmap ;2 :BufExplorer<CR>
"map  :TlistToggle<CR>
"TagList보다 Tagbar가 좀 더 우수하다
map ;3 :TagbarToggle<CR>
map ;4 :NERDTreeToggle $PWD<CR>
map ;5 :Gtags<SPACE>
map ;6 :!bash<CR>


"Vim grep 설정
map <C-a> :noautocmd vimgrep <cword> `cat $MWPATH/db_files.out`




"term 변경
set term=xterm
set t_Co=256
" gnu global 자동 갱신 설정
let Gtags_Auto_Update=1   
let Gtags_No_Auto_Jump=1


" vundle 설정 ===================================
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
"Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
Plugin 'L9'
" Git plugin not hosted on GitHub
"Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
"Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
"Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Avoid a name conflict with L9
"Plugin 'user/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

Plugin 'DoxygenToolkit.vim'
Plugin 'The-NERD-tree'
Plugin 'Tagbar'
Plugin 'bufexplorer.zip'
" Plugin 'Valloric/YouCompleteMe'
" Airline 설치
Plugin 'vim-airline/vim-airline'
" Audo Tag 설치 ; ctag/cscope 갱신기능
Plugin 'AutoTag'
" ultisnips 설정 - engine  
Plugin 'SirVer/ultisnips'  
" ultisnips 설정 - engine  
Plugin 'honza/vim-snippets'
" cpp syntax 설정
Plugin 'octol/vim-cpp-enhanced-highlight'

" ctrlp 설정
Plugin 'ctrlpvim/ctrlp.vim'

" syntastic 설정
Plugin 'scrooloose/syntastic'

" vim fugitive
Plugin 'tpope/vim-fugitive'
Plugin 'airblade/vim-gitgutter'


" vundle 설정  end===============================

" YCM 설정 ===========================
"let g:ycm_global_ycm_extra_conf = "~/.vim/.ycm_extra_conf.py"
"let g:ycm_key_list_select_completion=[]  
"let g:ycm_key_list_previous_completion=[]
"let g:ycm_autoclose_preview_window_after_completion=1
"let g:ycm_show_diagnostics_ui = 0


" vimplug 설정     ===============================                               
call plug#begin('~/.vim/plugged')                                                
Plug 'terryma/vim-multiple-cursors'
Plug 'neoclide/coc.nvim', {'branch': 'release'}                                  
Plug 'OmniSharp/omnisharp-vim'
call plug#end()                                                                  
" vimplug 설정  end===============================    

" omnisharp 설정 =====
let g:OmniSharp_server_stdio = 1
let g:OmniSharp_server_use_mono = 1
let g:OmniSharp_highlight_types = 2
" ====================

" coc 설정 ===========================
" if hidden is not set, TextEdit might fail.
set hidden

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" Or use `complete_info` if your vim support it, like:
" inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Create mappings for function text object, requires document symbols feature of languageserver.
xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)

" Use <C-d> for select selections ranges, needs server support, like: coc-tsserver, coc-python
"nmap <silent> <C-d> <Plug>(coc-range-select)
"xmap <silent> <C-d> <Plug>(coc-range-select)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add status line support, for integration with other plugin, checkout `:h coc-status`
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

" ====================================

"highlight 색깔 변경
hi Comment term=NONE ctermfg=white guifg=#80a0ff gui=bold
hi Function term=bold ctermfg=Green guifg=#80a0ff gui=bold
hi String term=bold ctermfg=Blue guifg=#80a0ff gui=bold
hi Number term=NONE ctermfg=Gray guifg=#80a0ff gui=bold
hi Title        term=bold ctermfg=Yellow guifg=Brown gui=bold
hi Character    term=bold ctermfg=Brown guifg=Brown gui=bold
hi Boolean      term=bold ctermfg=Brown guifg=Brown gui=bold
hi Constant      term=bold ctermfg=Red guifg=Brown gui=bold
highlight Pmenu ctermfg=14 ctermbg=0 guifg=#00ff00 guibg=#0000ff

" color column
set colorcolumn=81
highlight ColorColumn ctermbg=magenta
autocmd FileType python set shiftwidth=2 tabstop=2 expandtab
"""
g_strVIMRC_writemode ='w'



g_downloadtool='wget'
g_package_list = [
     # info, url,filename
    ["cvim.zip	6.1.1	2014-04-21","http://www.vim.org/scripts/download_script.php?src_id=21803","cvim.zip"],
#    ["nerdtree.zip   4.2.0   2011-12-28","http://www.vim.org/scripts/download_script.php?src_id=17123","nerdtree.zip" ],
#    ["tagbar.vmb 2.6.1   2014-01-23","http://www.vim.org/scripts/download_script.php?src_id=21362","tagbar.vmb" ],
#    ["bufexplorer-7.4.6.zip  7.4.6   2014-11-04","http://www.vim.org/scripts/download_script.php?src_id=22601","bufexplorer-7.4.6.zip" ],
#    ["DoxygenToolkit.vim 0.2.13  2010-10-16","http://www.vim.org/scripts/download_script.php?src_id=14064","DoxygenToolkit.vim" ],
    ["taghighlight_r2.1.4.zip    2.1.4   2011-12-15","http://www.vim.org/scripts/download_script.php?src_id=17066","taghighlight_r2.1.4.zip"],
]

def download_file(url,filename,target_dir):
    cmd = g_downloadtool + ' '+ url +' -O '+target_dir+'/'+filename
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print('Error on downloading file;',filename)
        return False
    print('OK')
    return True

    
def install_vundle(str_target_path):
  # :x: check the installation of the git
  cmd = """git --version """
  output=subprocess.call (cmd, shell=True)    
  if output!=0:
    print("No git in this system, install the git")
    print("ex)  $ sudo apt-get install git")
    return False
  
  # :x: try the vundle installation
   
  if (os.path.isdir(g_strMYBIN+"/vundle") == False) :
    cmd = """git clone https://github.com/gmarik/Vundle.vim.git """+ g_strMYBIN+"/vundle"
    print (cmd)
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print("Error on downloading file")
        return False
  else :
    print ("Vundle is already downloaded")

  cmd = """cp -rf """+ g_strMYBIN+"/vundle/* "+str_target_path
  print (cmd)
  output=subprocess.call (cmd, shell=True)    
  if output!=0:
    print("Error on copy files")
    return False

  cmd = """rm -rf """+ g_strMYBIN+"/vundle "
  print (cmd)
  output=subprocess.call (cmd, shell=True)    
  if output!=0:
    print("Error on copy files")
    return False



  print("OK")
  return True

def install_plugins_vundle():
    cmd = """vim +BundleInstall +qall """
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print("Error on installing")
        return False
    print("OK")
    return True

def install_vimplug():
    # :x: try the vimplug installation
    cmd = """curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim """
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print("Error on downloading file")
        return False
    print("OK")
    return True

def install_plugins_vimplug():
    cmd = """vim +PlugInstall +qall """
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print("Error on installing")
        return False
    print("OK")
    return True

def install_ccls():
    cmd = 'mkdir ~/my_bin/ccls_install' 
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print("Error on create directory")
        return False

    cmd = 'git clone --depth=1 --recursive https://github.com/MaskRay/ccls ~/my_bin/ccls_install' 
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print("Error on cloning")
        return False

    cmd = 'cd ~/my_bin/ccls_install ; cmake -H. -BRelease -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/usr/lib/llvm-8 && cmake --build Release' 
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print("Error on configuration & build")
        return False

    cmd = 'ln -s ~/my_bin/ccls_install/Release/ccls ~/my_bin/ccls' 
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print("Error on making symbolic link")
        return False

    print("OK")
    return True


def install_ycm():
    cmd = """cd ~/.vim/bundle/YouCompleteMe ; ./install.py --clang-completer    """
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print("Error on installing")
        print("check the following packages ; build-essential, cmake, python-dev ")
        print("ex) sudo apt-get install build-essential cmake ")
        print("    sudo apt-get install python-dev ")
        return False
    print("OK")
    return True

   
  

def download_packages():
    for item in g_package_list:
        print("Download ["+item[0]+"]") # package info
        
        if os.path.isfile(g_strVIM_SETTING+'/'+item[2]) == True:
            print("Already it has the file ; "+g_strVIM_SETTING+'/'+item[2])
            continue 
        if download_file(item[1],item[2],g_strVIM_SETTING) != True:
            print("error on ["+item[0]+"]")
            return False
        else:
            print("Download Done ["+item[0]+"]")
    return True
def install_packages():

    for item in g_package_list:
        cmd=""
        # check file type and install the plugin according to file type
        if item[2][-4:] =='.zip' :
            cmd="cd "+g_strVIM_SETTING+";"+"unzip "+g_strVIM_SETTING+"/"+item[2]+";cd -"
            print("zip!")
        elif item[2][-4:] =='.vmb' :
            cmd="cd "+g_strVIM_SETTING+";"+"vim -c \'so %\' -c \'q\' "+item[2]+";cd -"
            print("vmb")
        elif item[2][-4:] =='.vim' :
            cmd="cp "+g_strVIM_SETTING+"/"+item[2]+" "+g_strVIM_SETTING+"/plugin/"+item[2]
            print("vim")
        else:
            print("Error, cannot find the file type on package[",item[0],"]")
            return False
        output=subprocess.call (cmd, shell=True)    
        if output!=0:
            print('Error on install package;',item[0])
            return False
        print('OK')

    return True


##
# @brief check the directory if not exist make it
#
# @param targetPath[IN] the path to make
#
# @return True when it success
def check_directory_or_make(targetPath):
    print ('check',targetPath, 'directory')
    if os.path.isdir(targetPath) == False:
        if os.mkdir(targetPath) == False:
            return False
    else:
        print (targetPath,"is already exist")
    return True

def check_directories():
    # :x: The directories to check
    directories = [
        g_strMYBIN ,        # ~/my_bin
        g_strVIM_SETTING    # ~/.vim
        ]
    for item in directories :
        if check_directory_or_make(item) == False :
            print('Error on ',item)
            return False
    return True
def add_script(contents):
    writeFlag=False
    targetfilename = contents[0]
    scriptcontents = contents[1]
    writemode = contents[2]
    
    if writemode == 'a' and os.path.isfile(targetfilename) == True :
        # :x: to prevent rewriting same script
        f = open(targetfilename,'r')
        script = f.read()
        if script.find('# _:x:_ Add Script for the dev. environment') == -1 :
            writeFlag = True
        else :
            print("the script for "+targetfilename+" is already existed")
        f.close()
    elif writemode =='w' :
        writeFlag = True

    if writeFlag == True :
        f = open(targetfilename,writemode)
        f.write(scriptcontents)
        f.close()
    if writemode == 'w' :
        os.chmod(targetfilename,0o700)
    return True

def add_scripts():
    print('make additional scripts like .bashrc')

    scripts =[ #filename, script to write, write mode 'w'(write) 'a'(add)
               [g_strBASHRC_filename,g_strBashrc_script,g_strBashrc_writemode],
               [g_strMW_filename,g_strMW_script,g_strMW_writemode],
               [g_strMdb_files_filename,g_strMdb_files_script,g_strMdb_files_writemode],
               [g_strMdb_ctags_filename,g_strMdb_ctags_script,g_strMdb_ctags_writemode],
               [g_strMdb_main_ctags_filename,g_strMdb_main_ctags_script,g_strMdb_main_ctags_writemode],
               [g_strVIMRC_filename,g_strVIMRC_script,g_strVIMRC_writemode],
               [g_strTMUX_conf_filename,g_strTMUX_conf_script,g_strTMUX_conf_writemode],
               [g_strCocSettings_filename,g_strCocSettings_script,g_strCocSettings_writemode],
               [g_strCCLS_Setting_filename,g_strCCLS_Setting_script,g_strCCLS_Setting_writemode],
            ]
    for item in scripts:
        if add_script(item) != True:
            return False
    return True

g_STR_global_version_name ='global-6.6.3'
g_STR_global_compressed_name=g_STR_global_version_name+".tar.gz" 
g_STR_global_URL= 'https://ftp.gnu.org/pub/gnu/global/'+g_STR_global_version_name+'.tar.gz'

def install_gnu_global():
    print('install GNU global ; ',g_STR_global_compressed_name)
    print('download the ',g_STR_global_compressed_name)

    if os.path.isfile('.'+'/'+g_STR_global_compressed_name) == True:
        print("Already it has the file ; "+g_strVIM_SETTING+'/'+g_STR_global_compressed_name)
    else :
        if download_file(g_STR_global_URL,g_STR_global_compressed_name,'.') == False :
            print('download error!')
            return False
    print('extract ',g_STR_global_compressed_name)
    cmd = 'tar xf ' +g_STR_global_compressed_name
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print('Error on extract file;',g_STR_global_compressed_name)
        return False
    print('build GNU global and install on ~/my_bin/global')



    cmd = 'mkdir ~/my_bin/global ' 
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print('Error on make directory ~/my_bin/global;')

    cmd = 'cd '+ g_STR_global_version_name+' && ./configure --prefix=$HOME/my_bin/global && make && make install'
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print('Error on installation')
        return False
    print('copy vim plugin for gnu global')
    cmd = 'cp ~/my_bin/global/share/gtags/gtags.vim ~/.vim/plugin'
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print('Error on extract file;',g_STR_global_compressed_name)
        return False
    
    print('clean up gnu global files')
    cmd = 'rm ' +g_STR_global_compressed_name+ ' && rm -rf '+g_STR_global_version_name 
    output=subprocess.call (cmd, shell=True)    
    if output!=0:
        print('Error on cleanup files')
        return False


    print('GNU global installation done')
    return True



def main():
    nPhase =0
    print ("Development Environment setting is now start")
    print ("2019.10.08 by windheim")
    print ("Before install, check the prerequisite packages")
    print ("Prerequisites ; ")
    print (g_strPrerequisites)

    # base directory (my_bin, .vim) 만들기 
    nPhase+=1
    print ("Phase #",nPhase," ; Check the base directories")
    if check_directories() == False :
        print ("Error on Phase #",nPhase)
        return False

    # vundle의 설치
    nPhase+=1
    print ("Phase #",nPhase," ; install vundle")
    if install_vundle(g_strVIM_SETTING) == False :
        print("Error on Phase #",nPhase)
        return False

    # vimplugin의 설치
    nPhase+=1
    print ("Phase #",nPhase," ; Download vim plugins")
    if download_packages() == False :
        print("Error on Phase #",nPhase)
        return False
    nPhase+=1
    print ("Phase #",nPhase," ; Install vim plugins")
    if install_packages() == False :
        print("Error on Phase #",nPhase)
        return False
    
    # script 생성
    nPhase+=1
    print ("Phase #",nPhase," ; Make additional scripts(.bashrc,.vimrc)")
    if add_scripts() == False :
        print("Error on Phase #",nPhase)
        return False

    # vim-plug의 설치
    nPhase+=1
    print ("Phase #",nPhase," ; install vim-plug")
    if install_vimplug() == False :
        print("Error on Phase #",nPhase)
        return False

    # vundle 내 plugin 설치
    nPhase+=1
    print ("Phase #",nPhase," ; install plugins in vundle")
    if install_plugins_vundle() == False :
        print("Error on Phase #",nPhase)
        return False

    # vim-plug 내 plugin 설치
    nPhase+=1
    print ("Phase #",nPhase," ; install plugins in vim-plug")
    if install_plugins_vimplug() == False :
        print("Error on Phase #",nPhase)
        return False
    ## ycm 설치
    #nPhase+=1
    #print ("Phase #",nPhase," ; install YCM(YouCompleteMe) plugin in vundle")
    #install_ycm()
    #if install_ycm() == False :
    #    print("Error on Phase #",nPhase)
    #    return False
   
    # gnu global 생성
    nPhase+=1
    print ("Phase #",nPhase," ; install GNU global manually")
    if install_gnu_global() == False :
        print("Error on Phase #",nPhase)
        return False



    # install ccls (c/c++ parser)
    nPhase+=1
    print ("Phase #",nPhase," ; install ccls the c/c++ parser")
    if install_ccls() == False :
        print("Error on Phase #",nPhase)
        return False
   
    return True

    
# ========unit test====================================
def remove_file_if_exist(strPath):
    ret = False
    # :x: find out the test directory , if it exists delete it
    if os.path.exists(strPath) == True:
        cmd = 'rm -rf ' +strPath 
        output=subprocess.call (cmd, shell=True)   
        if output != 0:
            ret = False
        else:
            ret = True 
    else:
        ret = True
    return ret

class vundle_install_test(unittest.TestCase):
    str_Test_dir_path="./test_vundle"
    def setUp(self):
        print("setup ; vundle install test")
        # :x: find out the test directory , if it exists delete it
        if remove_file_if_exist(self.str_Test_dir_path) != True:
           print("test path remove error") 

    def tearDown(self):
        print("teardown ; vundle install test")
        # :x: find out the test directory , if it exists delete it
        if remove_file_if_exist(self.str_Test_dir_path) != True:
           print("test path remove error") 

    def test_vundle_install(self):
        # :x: try install the vundle & check it
        self.assertTrue(install_vundle(self.str_Test_dir_path))

# =====================================================

if __name__ == '__main__':
    main()
    #unittest.main()
