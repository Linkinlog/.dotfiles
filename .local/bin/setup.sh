#!/usr/bin/env bash

# This script sets up a development environment for a Linux-based system.
# It installs and configures various tools, packages, and configurations
# necessary for a comfortable and efficient development experience.
#
# Currently only supported on ubuntu and ubuntu derivitives, built for 22.04
# Written by: https://github.com/linkinlog

# Exit if anything fails (has an exit code of 1)
set -e

# Set arguments
readonly HOSTNAME="$1"
readonly GIT_EMAIL="$2"
readonly GIT_USER="$3"
readonly GH_PERSONAL_TOKEN="$4"
readonly HOMEDIR="$HOME"

## Tools
readonly TOOLS=("ssh" "gh" "git" "xclip" "docker" "ripgrep" "tmux" "zsh" "brave-browser" "i3")
readonly DEPS=("ninja-build" "gettext" "libtool-bin" "cmake" "g++" "pkg-config" "unzip" "curl" "python3" "python3-pip" "bsdutils" "cmake" "dpkg-dev" "fakeroot" "gcc" "g++" "libegl1-mesa-dev" "libssl-dev" "libfontconfig1-dev" "libwayland-dev" "libx11-xcb-dev" "libxcb-ewmh-dev" "libxcb-icccm4-dev" "libxcb-image0-dev" "libxcb-keysyms1-dev" "libxcb-randr0-dev" "libxcb-render0-dev" "libxcb-xkb-dev" "libxkbcommon-dev" "libxkbcommon-x11-dev" "libxcb-util0-dev" "lsb-release" "python3" "xdg-utils" "xorg-dev")

# Make sure all variables and dependencies exist
validate() {
    printf "Validating arguments...\n\n"
    if [ "$HOSTNAME" = "" ] || [ "$GIT_EMAIL" = "" ] || [ "$GIT_USER" = "" ] || [ "$GH_PERSONAL_TOKEN" = "" ]; then
        printf "Usage: %s <hostname> <git_email> <git_user> <gh_personal_token> \n\n" "$0"
        exit 1
    fi
    printf "Validated. Continuing...\n\n"
}

# Ensure all dependencies are here after installation
check_dependencies() {
    printf "Checking dependencies...\n\n"
    if ! git --version >/dev/null 2>&1; then
        printf "Git is not installed. Please install Git and try again.\n\n"
        exit 1
    fi

    if ! curl --version >/dev/null 2>&1; then
        printf "Curl is not installed. Please install Curl and try again.\n\n"
        exit 1
    fi

    if ! wget --version >/dev/null 2>&1; then
        printf "Wget is not installed. Please install Wget and try again.\n\n"
        exit 1
    fi

    if ! unzip -v >/dev/null 2>&1; then
        printf "Unzip is not installed. Please install Unzip and try again.\n\n"
        exit 1
    fi

    if ! dpkg -s build-essential >/dev/null 2>&1; then
        printf "Build-essential is not installed. Please install Build-essential and try again.\n\n"
        exit 1
    fi
    printf "All dependencies set. Continuing...\n\n"
}


# Refresh sudo auth so we can ask for password less
refresh_sudo() {
    printf "Refreshing sudo authentication... \n\n"
    sudo -v
}

# Installs whatever package list is passed in
# @param Array package_list
install_packages() {
    local package_manager
    local package_list=("$@")

    printf "Determining package manager... \n\n"
    if command -v apt-get >/dev/null 2>&1; then
        package_manager="apt-get"
        sudo apt-get update -q > /dev/null
    elif command -v dnf >/dev/null 2>&1; then
        package_manager="dnf"
    elif command -v pacman >/dev/null 2>&1; then
        package_manager="pacman"
        sudo pacman -Sy
    elif command -v zypper >/dev/null 2>&1; then
        package_manager="zypper"
        sudo zypper refresh
    else
        printf "No supported package manager found.\n\n"
        exit 1
    fi

    printf "Using %s as package manager and installing...\n\n" "$package_manager"
    sudo "$package_manager" -qy install "${package_list[@]}" > /dev/null
    printf "All packages installed. Continuing...\n\n"
}

## Setting up brave gpg key
add_brave_repo() {
    printf "Adding Brave GPG key if needed...\n\n"
    local brave_gpg=https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    local gpg_output=/usr/share/keyrings/brave-browser-archive-keyring.gpg
    if output=$(sudo wget -O $gpg_output $brave_gpg  2>&1); then
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo bash -c 'cat > /etc/apt/sources.list.d/brave-browser-release.list'
    else
        printf "Error occurred: %s\n" "$output"
        exit 1
    fi
    printf "Brave all set to be installed. Continuing...\n\n"
}

# Use Rustup to install Rust stable
install_rust() {
    printf "Installing Rust stable with Rustup...\n\n"
    curl https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain stable -y > /dev/null
    printf "Rust stable installed. Continuing...\n\n"
}

# Installing various cargo tools
# for now just tree-sitter.
install_rust_tools() {
    printf "Installing tools that need cargo...\n\n"
    # Add Rust to PATH (taken from .cargo/env)
    export PATH="$HOMEDIR/.cargo/bin:$PATH"
    if ! command -v cargo >/dev/null 2>&1; then
        printf "Cargo not found...exiting\n\n"
        exit 1
    else
        cargo install tree-sitter-cli > /dev/null
        printf "tree-sitter-cli installed \n\n"
    fi
    printf "Cargo tools installed. Continuing...\n\n"
}

# Installing our terminal emulator, wezterm
install_wezterm() {
    local wezterm_version
    local release
    wezterm_version=$(curl -s "https://api.github.com/repos/wez/wezterm/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
    release=$(lsb_release -rs)
    printf "Installing WezTerm version %s...\n\n" "$wezterm_version"
    if output=$(curl -LO "https://github.com/wez/wezterm/releases/download/${wezterm_version}/wezterm-${wezterm_version}.Ubuntu${release}.deb" 2>&1); then
        sudo apt-get install -yq "./wezterm-${wezterm_version}.Ubuntu${release}.deb" > /dev/null
    else
        printf "Error occured: %s\n" "$output"
    fi
    printf "Wezterm installed. Continuing...\n\n"
}

# Installing Go from source and deleting old copies
install_go() {
    local go_version
    local arch
    local go_install_path
    go_version=$(curl -sSL "https://golang.org/VERSION?m=text")
    arch="linux-amd64"
    go_install_path="$HOME/${go_version}.${arch}.tar.gz"
    if [[ "$(go version | awk '{print $3}')" == "go${go_version}" ]]; then
        printf "Go version %s is already installed\n\n" "$go_version"
        return
    fi

    if output=$(sudo wget -O "$go_install_path" "https://go.dev/dl/${go_version}.${arch}.tar.gz" 2>&1); then
        printf "Installing Go version %s to %s\n\n" "$go_version" "$go_install_path"
        sudo rm -rf /usr/local/go && 
        sudo tar -C /usr/local -xzf "${go_version}.${arch}.tar.gz" >/dev/null
    else
        printf "Error occurred: %s\n" "$output"
        exit 1
    fi
    printf "Go installed. Continuing...\n\n"
    export PATH="$PATH:/usr/local/go/bin"
}

# Install all recommended Go tools
install_go_tools() {
    printf "Installing Go tools...\n\n"
    if command -v go >/dev/null 2>&1; then
        local go_tools=(
        "github.com/davidrjenni/reftools/cmd/fillstruct@latest"
        "github.com/go-delve/delve/cmd/dlv@latest"
        "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
        "github.com/uber/go-torch@latest"
        "github.com/fatih/gomodifytags@latest"
        "github.com/josharian/impl@latest"
        "github.com/golang/mock/mockgen@latest"
        "github.com/onsi/ginkgo/ginkgo@latest"
        "github.com/cweill/gotests/gotests@latest"
        "github.com/rogpeppe/godef@latest"
        "github.com/godoctor/godoctor@latest"
        "github.com/segmentio/golines@latest"
        "github.com/alvaroloes/enumer@latest"
        "golang.org/x/tools/cmd/goimports@latest"
        "golang.org/x/tools/cmd/gorename@latest"
        "golang.org/x/tools/cmd/guru@latest"
        "mvdan.cc/gofumpt@latest"
    )

    for tool in "${go_tools[@]}"; do
        GO111MODULE=on go install "$tool" > /dev/null
    done
    fi
    printf "Go tools installed. Continuing...\n\n"
}

# We use packer for plugin management in Neovim, so install that.
# We use TPM for plugin management in Tmux, so install that.
install_terminal_tools() {
    local packer_repo="https://github.com/wbthomason/packer.nvim"
    local packer_dir="$HOMEDIR/.local/share/nvim/site/pack/packer/start/packer.neovim"
    local tpm_repo="https://github.com/tmux-plugins/tpm"
    local tpm_dir="$HOMEDIR/.tmux/plugins/tpm"

    printf "Installing TPM and Packer...\n\n"

    if [ -d "$packer_dir" ]; then
        git -C "$packer_dir" pull > /dev/null
    else
        git clone --depth 1 "$packer_repo" "$packer_dir" > /dev/null
    fi

    if [ -d "$tpm_dir" ]; then
        git -C "$tpm_dir" pull > /dev/null
    else
        git clone "$tpm_repo" "$tpm_dir" > /dev/null
    fi

    printf "Packer and TPM should be installed! Be sure to run :PackerSync and <prefix>+I to install each respectively. Continuing...\n\n"
}

# Lazygit makes working with Git in the CLI much nicer, so install it.
install_lazygit() {
    printf "Installing lazygit...\n\n"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    if output=$(curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" 2>&1); then
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        printf "Installed Lazygit. Continuing...\n\n"
    else
        printf "Failed cURL'ing lazygit \n\n"
    fi
}


# Lazydocker makes working with Docker in the CLI much nicer, so install it.
install_lazydocker() {
    printf "Installing lazydocker...\n\n"
    if output=$(curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash 2>&1); then
        printf "Installed Lazydocker \n\n"
    else
        printf "Error: Failed to install Lazydocker\n\n"
    fi
    printf "Installed lazydoker. Continuing...\n\n"
}

# I cant write code without vim, apologies
install_neovim() {
    local neovim_repo="https://github.com/neovim/neovim"
    local neovim_dir="$HOMEDIR/neovim-build"
    
    printf "Installing Neovim...\n\n"

    if [ -d "$neovim_dir" ]; then
        git -C "$neovim_dir" pull > /dev/null
        rm -rf "$neovim_dir/build" > /dev/null
    else
        git clone --depth 1 "$neovim_repo" "$neovim_dir" > /dev/null
    fi
    cd "$neovim_dir" && make CMAKE_BUILD_TYPE=RelWithDebInfo > /dev/null
    sudo make install > /dev/null || { printf "Error: failed installing neovim \n\n"; exit 1; }
    printf "Installed neovim. Continuing...\n\n"
}

# :checkhealth says I need python I guess
install_neovim_tools() {
    if ! command -v pip3 >/dev/null 2>&1; then
        printf "Pip3 not found...exiting \n\n"
        exit 1
    else
        pip3 install neovim > /dev/null
        printf "Installed python-neovim. Continuing...\n\n"
    fi
}

# Change the hostname to whatever was set
set_hostname() {
    if [ "$HOSTNAME" != "" ]; then
        sudo su -c "echo '$HOSTNAME' > /etc/hostname"
        export HOST=$HOSTNAME
        printf "Hostname set to %s. Continuing...\n\n" "$HOSTNAME"
    fi
}

# Configure local git
config_git() {
    git config --global user.email "$GIT_EMAIL"
    git config --global user.name "$GIT_USER"
    printf "Git configured to use %s as email and %s as user. Continuing...\n\n" "$GIT_EMAIL" "$GIT_USER"
}

# Use systemd to start and enable ssh so we can connect
start_enable_ssh() {
    sudo systemctl start ssh > /dev/null
    sudo systemctl enable ssh > /dev/null
    printf "SSH started and enabled. Continuing...\n\n"
}

# Take the personal token that was made, auth with it, and add the ssh key
# Necessary since we use git submodules with SSH
setup_github() {
    printf "Setting up GitHub...\n\n"

    if ! gh auth status >/dev/null 2>&1; then
        printf "Adding Token %s \n\n" "$GH_PERSONAL_TOKEN"
        gh auth login --with-token <<< "$GH_PERSONAL_TOKEN"
    fi

    if [ ! -f "$HOME/.ssh/github" ]; then
        # Make new ssh key for gh
        printf "Creating ssh key for GitHub for %s...\n\n" "$HOST"
        ssh-keygen -f ~/.ssh/github -N ""
        printf "Adding ssh key to github"
        gh ssh-key add "$HOMEDIR/.ssh/github.pub" --title "$HOST"
    fi
    printf "GitHub setup finished. Continuing...\n\n"
}

# Heres the meat and potatoes, our bare repo will be unpacked
setup_git_repo() {
    printf "Setting up Git repo \n\n"
    local dotfiles_repo="https://github.com/linkinlog/.dotfiles"
    local dotfiles_dir="$HOMEDIR/.dotfiles"

    if [ -d "$dotfiles_dir" ]; then
        git --git-dir="$dotfiles_dir" --work-tree="$HOMEDIR" pull > /dev/null
    else
        git clone --bare "$dotfiles_repo" "$dotfiles_dir" > /dev/null
    fi
    git --git-dir="$dotfiles_dir" --work-tree="$HOMEDIR" checkout > /dev/null
    printf "Setting up bare repo's submodules \n\n"
    GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no' git --git-dir="$dotfiles_dir" --work-tree="$HOMEDIR" submodule update --init --remote > /dev/null
    printf ".dotfiles repo setup finished. Continuing...\n\n"
}

# Mainly just for the theme, hoping to phase out at some point
setup_ohmyzsh() {
    printf "Setting up OhMyZsh\n\n"

    if [ ! -d "$HOMEDIR/.oh-my-zsh" ]; then
        export RUNZSH=no
        export KEEP_ZSHRC=yes
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            "" --unattended || { printf "Error: could not install OhMyZsh \n\n"; exit 1; }
        chsh -s "$(which zsh)"
    else
        git -C "$HOMEDIR/.oh-my-zsh" pull > /dev/null
    fi

    local zsh_syntax_highlighting_path="${ZSH_CUSTOM:-$HOMEDIR/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    if [ -d "$zsh_syntax_highlighting_path" ]; then
        git -C "$zsh_syntax_highlighting_path" pull > /dev/null
    else
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_syntax_highlighting_path" || { printf "Error: could not clone zsh-syntax-highlighting \n\n"; exit 1;} > /dev/null
    fi

    local zsh_autosuggestions_path="${ZSH_CUSTOM:-$HOMEDIR/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [ -d "$zsh_autosuggestions_path" ]; then
        git -C "$zsh_autosuggestions_path" pull > /dev/null
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_autosuggestions_path" || { printf "Error: could not clone zsh-autosuggestions \n\n"; exit 1;} > /dev/null
    fi
    printf "OhMyZsh, zsh-syntax-highlighting, and zsh-autosuggestions installed. Continuing...\n\n"
}


# Group the dependency commands together
install_dependencies() {
    validate
    add_brave_repo
    install_packages "${DEPS[@]}" "${TOOLS[@]}"
    check_dependencies
}

# Group the env setup commands together
configure_environment() {
    set_hostname
    config_git
    start_enable_ssh
    refresh_sudo
    (install_go)
    (install_go_tools)
    (install_lazydocker)
    (install_lazygit)
    refresh_sudo
    (install_neovim)
    (install_neovim_tools)
    (install_rust)
    (install_rust_tools)
    (install_terminal_tools)
    (setup_github)
    (setup_git_repo)
    (setup_ohmyzsh)
    refresh_sudo
    (install_wezterm)
}

# Run it all and only care about STDERR
main() {
    install_dependencies
    configure_environment
}

main "$@"
