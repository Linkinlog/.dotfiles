#!/usr/bin/env bash

# Install deps
if command -v apt-get >/dev/null 2>&1; then
    echo "Using apt as package manager."
    echo "Installing dependencies with apt..."
    sudo apt-get install git ssh gh -qy
elif command -v dnf >/dev/null 2>&1; then
    echo "Using dnf as package manager."
    echo "TODO"
    exit 1
else
    echo "No supported package manager found."
    exit 1
fi

# Clone and checkout git repo
echo "Setting up Git repo"
git clone --bare https://github.com/linkinlog/.dotfiles $HOME/.dotfiles
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout

# Begin setup
echo "Annnd we're off!"
command "$HOME/.local/bin/dev_setup"
