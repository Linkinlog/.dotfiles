{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "my-shell";
  buildInputs = [
    pkgs.git
    pkgs.gh
    pkgs.neovim
    pkgs.lazygit
    pkgs.tmux
    pkgs.xclip
    pkgs.tree-sitter
    pkgs.docker
    pkgs.wezterm
    pkgs.ripgrep
    pkgs.zsh
    pkgs.go
    pkgs.rustup
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.gcc.cc.lib
    pkgs.autoconf
    pkgs.automake
    pkgs.clang
    pkgs.reftools
    pkgs.gofumpt
    pkgs.mockgen
    pkgs.delve
    pkgs.govulncheck
    pkgs.gotestsum
    pkgs.iferr
    pkgs.ginkgo
    pkgs.impl
    pkgs.richgo
    pkgs.golangci-lint
    pkgs.gomodifytags
    pkgs.gotests
  ];
  shellHook = ''
    export SHELL=$(which zsh)
    exec zsh
  '';
}

