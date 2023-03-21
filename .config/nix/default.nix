let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/22.11.tar.gz") {};
in {
  
  git     = pkgs.git;
  neovim  = pkgs.neovim;
  gh      = pkgs.gh;
  lazygit = pkgs.lazygit;
  
  go      = pkgs.go;
  rustup  = pkgs.rustup;
  bash    = pkgs.bash;
  zsh     = pkgs.zsh;
}
