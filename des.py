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
# export DISPLAY=:1

# for docker
alias docker='sudo docker'           


            """
g_strBashrc_writemode ='a' # :x: add the script in the end of .bashrc file

g_strTMUX_conf_filename=g_strHOME+"/.tmux.conf"
g_strTMUX_conf_script = """
set -g default-terminal "screen-256color"
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

nmap <F2> :BufExplorer<CR>
map <F3> :TagbarToggle<CR>
map <F4> :NERDTreeToggle $PWD<CR>
map <F8> :!bash<CR>

nmap ;2 :BufExplorer<CR>
map ;3 :TagbarToggle<CR>
map ;4 :NERDTreeToggle $PWD<CR>
map ;6 :!bash<CR>




"term 변경
set term=xterm
set t_Co=256

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
" Airline 설치
Plugin 'vim-airline/vim-airline'
" cpp syntax 설정
Plugin 'octol/vim-cpp-enhanced-highlight'

" ctrlp 설정
Plugin 'ctrlpvim/ctrlp.vim'

" vim fugitive
Plugin 'tpope/vim-fugitive'
Plugin 'airblade/vim-gitgutter'


" vundle 설정  end===============================


" vimplug 설정     ===============================                               
call plug#begin('~/.vim/plugged')                                                
Plug 'terryma/vim-multiple-cursors'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
call plug#end()                                                                  
" vimplug 설정  end===============================    

" vim-lsp 설정 ===================================
if executable('clangd')
    " pip install python-lsp-server
    au User lsp_setup call lsp#register_server({
        \ 'name': 'clangd',
        \ 'cmd': {server_info->['clangd']},
        \ })
endif

if executable('pylsp')
    " pip install python-lsp-server
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pylsp',
        \ 'cmd': {server_info->['pylsp']},
        \ 'allowlist': ['python'],
        \ })
endif

if executable('bash-language-server')
    " pip install python-lsp-server
    au User lsp_setup call lsp#register_server({
        \ 'name': 'bash-language-server',
        \ 'cmd': {server_info->['bash-language-server']},
        \ })
endif

if executable('cmake-language-server')
    au User lsp_setup call lsp#register_server({
      \ 'name': 'cmake',
      \ 'cmd': {server_info->['cmake-language-server']},
      \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'build/'))},
      \ 'whitelist': ['cmake'],
      \ 'initialization_options': {
        \   'buildDirectory': 'build',
      \ }
      \})
endif
function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> gs <plug>(lsp-document-symbol-search)
    nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
    nmap <buffer> gr <plug>(lsp-references)
    nmap <buffer> gi <plug>(lsp-implementation)
    nmap <buffer> gt <plug>(lsp-type-definition)
    nmap <buffer> <leader>rn <plug>(lsp-rename)
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
    nmap <buffer> K <plug>(lsp-hover)
    " :x: avoid mapping duplication:  nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
    " :x: avoid mapping duplication:  nnoremap <buffer> <expr><c-d> lsp#scroll(-4)

    let g:lsp_format_sync_timeout = 1000
    autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')

    " refer to doc to add more commands
endfunction

augroup lsp_install
    au!
    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END
let g:lsp_diagnostics_enabled = 0

" vim-lsp 설정 end ===============================

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
               [g_strVIMRC_filename,g_strVIMRC_script,g_strVIMRC_writemode],
               [g_strTMUX_conf_filename,g_strTMUX_conf_script,g_strTMUX_conf_writemode],
            ]
    for item in scripts:
        if add_script(item) != True:
            return False
    return True



def main():
    nPhase =0
    print ("Development Environment setting is now start")
    print ("2025.06.17 by windheim")
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
