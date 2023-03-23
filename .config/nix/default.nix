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
  docker         = pkgs.docker;
  wezterm        = pkgs.wezterm;
  ripgrep        = pkgs.ripgrep;
  ssh            = pkgs.openssh;
  # Langs
  go             = pkgs.go;
  gotools        = pkgs.go;
  rustup         = pkgs.rustup;
  python         = pkgs.python3;
  pip3           = pkgs.python3Packages.pip;
  # Deps
  gcc            = pkgs.gcc.cc.lib;
  autoconf       = pkgs.autoconf;
  automake       = pkgs.automake;
  clang          = pkgs.clang;
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
