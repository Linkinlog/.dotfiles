let
  pkgs           = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/22.11.tar.gz") {};
in {
  # Tools
  git            = pkgs.git;
  gh             = pkgs.gh;
  neovim         = pkgs.neovim;
  lazygit        = pkgs.lazygit;
  tmux           = pkgs.tmux;
  xclip          = pkgs.xclip;
  tree-sitter    = pkgs.tree-sitter;
  # Langs
  go             = pkgs.go;
  gotools        = pkgs.go;
  rustup         = pkgs.rustup;
  bash           = pkgs.bash;
  zsh            = pkgs.zsh;
  # Deps
  gcc            = pkgs.gcc.cc.lib;
  reftools       = pkgs.reftools;
  gofumpt        = pkgs.gofumpt;
  mockgen        = pkgs.mockgen;
  delve          = pkgs.delve;
  govulncheck    = pkgs.govulncheck;
  gotestsum      = pkgs.gotestsum;
  iferr          = pkgs.iferr;
  ginkgo         = pkgs.ginkgo;
  impl           = pkgs.impl;
  richgo         = pkgs.richgo;
  golangci-lint  = pkgs.golangci-lint;
  gomodifytags   = pkgs.gomodifytags;
  gotests        = pkgs.gotests;
}