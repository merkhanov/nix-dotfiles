# Declarative dotfiles via nix-darwin + home-manager

**Date:** 2026-06-27
**Status:** Approved (pending spec review)
**Repo:** `~/dotfiles` (`/Users/yernar33/dotfiles`)
**Host:** `Yernars-MacBook-Air` (aarch64-darwin)

## Goal

Manage all personal dotfiles **declaratively** through home-manager, integrated
into the existing nix-darwin flake. No external symlink managers (stow/chezmoi),
no install scripts, no imperative setup. A single **`just switch`** rebuilds the
entire system — macOS config *and* dotfiles — reproducibly from this one git repo.

## Constraints / principles

- **Fully declarative.** Every managed config is expressed as a home-manager
  option (`programs.*`) or home-manager-managed file. The only acceptable
  imperative residue is `source`-ing a handful of externally-installed tools from
  `initExtra` (see Known boundaries) — the *sourcing* is declared even if those
  tools are not yet Nix-managed.
- **Single source of truth.** One flake repo at `~/dotfiles`. The existing
  `/etc/nix-darwin/flake.nix` is migrated here and removed, so there is no second
  config path to drift.
- **One nixpkgs.** nix-darwin and home-manager both `follows` the same nixpkgs
  input (`nixpkgs-26.05-darwin`). home-manager pinned to `release-26.05`
  (verified to exist).
- **Reversible & safe.** `just build` (dry build) before every `just switch`.
  home-manager backs up any pre-existing unmanaged file to `<file>.bak` instead
  of clobbering it. Every step is a git commit; nix-darwin generations allow
  rollback.

## Current state (grounding)

- nix-darwin generation 1 is live (`darwin-version` → `26.05.adda04f`),
  bootstrapped at `/etc/nix-darwin`.
- Shell: `zsh` (`/bin/zsh`).
- Existing configs to bring under management:
  - `~/.gitconfig` — user name/email + git-lfs filter. Trivial.
  - `~/.vimrc` — 8 settings (number, relativenumber, showmatch, incsearch,
    hlsearch, ignorecase, smartcase). Trivial.
  - `~/.config/nvim/init.vim` — Vimscript via **vim-plug** with 6 plugins
    (nerdtree, nerdcommenter, vim-devicons, vim-airline, vim-airline-themes,
    coc.nvim). NOT trivial — full declarativeness means managing these via
    nixpkgs instead of vim-plug's runtime `:PlugInstall` (see Open questions).
  - `~/.zshrc` — PATH exports + sourcing tools (nvm, bun, `ng`/opencode/bun
    completions, Homebrew `zsh-autosuggestions`, an ai-autocomplete plugin in
    `~/Documents/GitHub`). Maps to `programs.zsh` + `sessionPath` + `initExtra`.

## Architecture

### Repo layout
```
~/dotfiles/
├── flake.nix              # inputs: nixpkgs, nix-darwin, home-manager (pinned 26.05)
├── flake.lock
├── configuration.nix      # nix-darwin SYSTEM config (moved out of the old flake.nix)
├── home.nix               # home-manager entry: imports home/*, home.packages (incl. just)
├── justfile               # switch / build / update / fmt / gc / rollback
├── .gitignore             # result, result-*, .DS_Store
├── docs/superpowers/specs/2026-06-27-declarative-dotfiles-home-manager-design.md
└── home/
    ├── git.nix            # programs.git
    ├── zsh.nix            # programs.zsh
    ├── vim.nix            # programs.vim
    └── neovim.nix         # programs.neovim + nixpkgs-managed plugins (no vim-plug)
```

### Flake wiring
- `inputs`: `nixpkgs` (`github:NixOS/nixpkgs/nixpkgs-26.05-darwin`),
  `nix-darwin` (`github:nix-darwin/nix-darwin/nix-darwin-26.05`, `follows` nixpkgs),
  `home-manager` (`github:nix-community/home-manager/release-26.05`, `follows` nixpkgs).
- `darwinConfigurations."Yernars-MacBook-Air"` = `darwinSystem` with modules:
  1. `./configuration.nix`
  2. `home-manager.darwinModules.home-manager`
  3. inline: `home-manager.useGlobalPkgs = true; home-manager.useUserPackages = true;`
     `home-manager.backupFileExtension = "bak";`
     `home-manager.users.yernar33 = import ./home.nix;`
- Result: `darwin-rebuild switch` builds the system and activates the
  home-manager generation in one step. No separate `home-manager` command.

### `justfile` recipes
| Recipe | Command |
|---|---|
| `just switch` | `sudo darwin-rebuild switch --flake .#Yernars-MacBook-Air` |
| `just build` | `darwin-rebuild build --flake .#Yernars-MacBook-Air` (no activation) |
| `just update` | `nix flake update` |
| `just fmt` | format all `*.nix` (nixfmt/nixpkgs-fmt) |
| `just gc` | `sudo nix-collect-garbage -d` |
| `just rollback` | `sudo darwin-rebuild switch --rollback` |

`just` is installed declaratively via `home.packages`.

## Config translation (all native home-manager modules)

| Source file | home-manager representation |
|---|---|
| `~/.gitconfig` | `programs.git.enable`, `userName = "Yernar Merkhanov"`, `userEmail = "yernarmerkhanov@gmail.com"`, `lfs.enable = true` |
| `~/.vimrc` | `programs.vim` — `settings`/`extraConfig` carrying the 8 options |
| `~/.config/nvim/init.vim` | `programs.neovim` — 6 plugins from nixpkgs `vimPlugins` (nerdtree, nerdcommenter, vim-devicons, vim-airline, vim-airline-themes, coc-nvim) replacing vim-plug; `withNodeJs = true` for coc.nvim; `extraConfig` = init.vim minus the `plug#begin/end` block. **Pending nvim decision — see Open questions.** |
| `~/.zshrc` | `programs.zsh.enable`; `autosuggestion.enable = true` (replaces Homebrew `zsh-autosuggestions` source line); `home.sessionPath` for `~/.bun/bin`, `~/.local/bin`, `~/.antigravity*/bin`, `~/.opencode/bin`; `initExtra` for the remaining `source` lines (nvm, completions, ai-autocomplete plugin) |

## Migration & cutover

1. Scaffold `~/dotfiles` repo (this spec already committed here).
2. Move `/etc/nix-darwin/flake.nix` content into `~/dotfiles` (split system config
   into `modules/darwin.nix`); add home-manager input + wiring; add `modules/home/*`.
3. `just build` — verify it evaluates and builds with no activation.
4. `just switch` — first activation. home-manager moves existing
   `~/.zshrc`, `~/.gitconfig`, `~/.vimrc`, `~/.config/nvim/init.vim` to `*.bak`.
5. Open a new shell; verify zsh/git/vim/nvim behave as before.
6. Remove `/etc/nix-darwin/flake.nix` (single source of truth is now `~/dotfiles`).
7. Commit each milestone; optionally push to GitHub.

## Known boundaries (explicitly out of scope for v1)

- **Externally-installed tools still sourced imperatively:** `nvm`, Antigravity,
  the `~/Documents/GitHub/ai-shell-autocompletion` plugin. v1 keeps `source`-ing
  them from `initExtra`. Future: nixify (`nvm` → `programs.zsh`/`nodejs`, etc.).
- **Homebrew** is not adopted into Nix in v1 (no `nix-homebrew` module yet).
- **nvim — coc.nvim extensions** (e.g. coc-tsserver) are installed by coc at
  runtime via `:CocInstall`; these stay coc-managed in v1 unless pinned via coc
  settings. The 6 plugins themselves become nixpkgs-managed (declarative). A
  **Nerd Font** is required for vim-airline/devicons glyphs (add via `fonts`).

## Success criteria

- `just switch` rebuilds system + dotfiles from `~/dotfiles` with no manual steps.
- After a fresh shell, `git`, `zsh` (with autosuggestions), `vim`, and `nvim`
  behave identically to before — sourced from declarative config.
- No `~/.zshrc`/`.gitconfig`/`.vimrc`/`init.vim` edited by hand; all are
  home-manager-managed (originals preserved as `*.bak`).
- `/etc/nix-darwin/flake.nix` removed; `~/dotfiles` is the only config path.
- Repo is a clean git history, each step committed.

## Open questions

**Resolved — none outstanding.**
- **nvim plugins:** managed **fully declaratively** via nixpkgs
  `programs.neovim.plugins` (vim-plug stripped) — the only choice consistent with
  the no-install-scripts rule.
- **System config file:** `configuration.nix` at the repo root (classic nix-darwin
  name); home-manager config in `home.nix` + `home/`.
- **Username/home centralization:** set `home.username` / `home.homeDirectory`
  once; everything else derives from `config.home.homeDirectory` so a future
  account rename is a one-line change.
- Repo location `~/dotfiles`, fully declarative native modules — decided.
