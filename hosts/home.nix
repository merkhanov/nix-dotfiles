{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;
in
{
  programs.home-manager.enable = true;

  # User packages (the `just` runner that drives this repo, etc.).
  home.packages = [ pkgs.just ];

  # PATH additions that used to be raw `export PATH=...` lines in .zshrc.
  # Derived from config.home.homeDirectory so they survive an account rename.
  home.sessionPath = [
    "${home}/.antigravity/antigravity/bin"
    "${home}/.antigravity-ide/antigravity-ide/bin"
    "${home}/.opencode/bin"
    "${home}/.local/bin"
    "${home}/.bun/bin"
  ];

  home.sessionVariables = {
    NVM_DIR = "${home}/.nvm";
    BUN_INSTALL = "${home}/.bun";
  };

  # --- git (from ~/.gitconfig) ---
  programs.git = {
    enable = true;
    userName = "Yernar Merkhanov";
    userEmail = "yernarmerkhanov@gmail.com";
    lfs.enable = true;
  };

  # --- zsh (from ~/.zshrc) ---
  # zsh-autosuggestions now comes from home-manager (replaces the Homebrew
  # `source` line). The remaining lines source externally-installed tools.
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    initContent = ''
      # Angular CLI autocompletion (only if `ng` is on PATH)
      command -v ng >/dev/null 2>&1 && source <(ng completion script)

      # nvm
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # bun completions
      [ -s "${home}/.bun/_bun" ] && source "${home}/.bun/_bun"

      # ai-shell autocompletion plugin
      [ -f "${home}/Documents/GitHub/ai-shell-autocompletion/ai-autocomplete.plugin.zsh" ] \
        && source "${home}/Documents/GitHub/ai-shell-autocompletion/ai-autocomplete.plugin.zsh"
    '';
  };

  # --- vim (from ~/.vimrc) ---
  programs.vim = {
    enable = true;
    extraConfig = ''
      set number
      set relativenumber
      set showmatch
      set incsearch
      set hlsearch
      set ignorecase
      set smartcase
    '';
  };

  # --- neovim (from ~/.config/nvim/init.vim) ---
  # Plugins come from nixpkgs (declarative) instead of vim-plug's :PlugInstall.
  # extraConfig is the original init.vim with the plug#begin/end block removed.
  programs.neovim = {
    enable = true;
    withNodeJs = true; # coc.nvim needs a Node runtime
    plugins = with pkgs.vimPlugins; [
      nerdtree
      nerdcommenter
      vim-devicons
      vim-airline
      vim-airline-themes
      coc-nvim
    ];
    extraConfig = ''
      " Кодировка UTF-8
      set encoding=utf8

      " Отключение совместимости с vi. Нужно для правильной работы некоторых опций
      set nocompatible

      " Игнорировать регистр при поиске
      set ignorecase

      " Не игнорировать регистр, если в паттерне есть большие буквы
      set smartcase

      " Подсвечивать найденный паттерн
      set hlsearch

      " Интерактивный поиск
      set incsearch

      " Размер табов - 2
      set tabstop=2
      set softtabstop=2
      set shiftwidth=2

      " Превратить табы в пробелы
      set expandtab

      " Таб перед строкой будет вставлять количество пробелов определённое в shiftwidth
      set smarttab

      " Копировать отступ на новой строке
      set autoindent
      set smartindent

      " Показывать номера строк
      set number

      " Относительные номера строк
      set relativenumber

      " Автокомплиты в командной строке
      set wildmode=longest,list

      " Подсветка синтаксиса
      syntax on

      " Разрешить использование мыши
      set mouse=a

      " Использовать системный буфер обмена
      set clipboard=unnamedplus

      " Быстрый скроллинг
      set ttyfast

      " Курсор во время скроллинга будет всегда в середине экрана
      set so=30

      " Встроенный плагин для распознавания отступов
      filetype plugin indent on

      " Автоматическое открытие NERDTree
      autocmd StdinReadPre * let s:std_in=1
      autocmd VimEnter * NERDTree | wincmd p

      " Включить/выключить NERDTree при нажатии \n
      nnoremap <leader>n :NERDTreeToggle<CR>
      " Юникодные иконки папок (Работает только с плагином vim-devicons)
      let g:WebDevIconsUnicodeDecorateFolderNodes = 1
      " Показывает количество строк в файлах
      let g:NERDTreeFileLines = 1
      " Игнорировать указанные папки
      let g:NERDTreeIgnore = ['^node_modules$', '^__pycache__$']
      " Закрыть vim, если единственная вкладка - это NERDTree
      autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

      let g:airline#extensions#tabline#enabled = 1
      let g:airline_powerline_fonts = 1
      let g:airline_statusline_ontop=0
      let g:airline_theme='deus'
      let g:airline#extensions#tabline#formatter = 'default'

      " Автокомплиты через Tab
      inoremap <expr> <Tab> coc#pum#visible() ? coc#pum#confirm() : "\<Tab>"
    '';
  };
}
