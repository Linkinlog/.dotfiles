let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/22.11.tar.gz") {};
in {
  
  git = pkgs.git;
  neovim = pkgs.neovim;
  gh = pkgs.gh;
  lazygit = pkgs.lazygit;
  
  go = pkgs.go;
  rustc = pkgs.rustc;
  cargo = pkgs.cargo;
  bash = pkgs.bash;
  zsh = pkgs.zsh;
}
