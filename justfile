host := "Yernars-MacBook-Air"

# List available recipes
default:
    @just --list

# Build & activate system + dotfiles (the cutover / apply-changes command)
switch:
    sudo darwin-rebuild switch --flake .#{{host}}

# Build only — evaluates everything, activates nothing (safe anytime)
build:
    darwin-rebuild build --flake .#{{host}}

# Update all flake inputs (nixpkgs, nix-darwin, home-manager)
update:
    nix flake update

# Format every Nix file in the repo
fmt:
    nix run nixpkgs#nixfmt-rfc-style -- $(git ls-files '*.nix')

# Garbage-collect old generations
gc:
    sudo nix-collect-garbage -d

# Roll back to the previous generation
rollback:
    sudo darwin-rebuild switch --rollback
