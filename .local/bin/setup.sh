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
readonly DEPS=("ninja-build" "gettext" "libtool-bin" "cmake" "g++" "pkg-config" "unzip" "curl" "python3" "python3-pip" "bsdutils" "cmake" "dpkg-dev" "fakeroot" "gcc" "g++" "libegl1-mesa-dev" "libssl-dev" "libfontconfig1-dev" "libwayland-dev" "libx11-xcb-dev" "libxcb-ewmh-dev" "libxcb-icccm4-dev" "libxcb-image0-dev" "libxcb-keysyms1-dev" "libxcb-randr0-dev" "libxcb-render0-dev" "libxcb-xkb-dev" "libxkbcommon-dev" "libxkbcommon-x11-dev" "libxcb-util0-dev" "lsb-release" "python3" "xdg-utils" "xorg-dev" "luarocks" "ruby" "ruby-dev" "php" "php-zip" "unzip" "openjdk-11-jdk" "julia" "powershell" "wget" "apt-transport-https" "software-properties-common")

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
    local opts=()
    local package_manager
    local upgrade_cmd
    local update_cmd="update"
    local install_cmd="install"
    local package_list=("$@")

    printf "Determining package manager... \n\n"
    if command -v apt-get >/dev/null 2>&1; then
        package_manager="apt-get"
        opts=(-y -qq)
        upgrade_cmd="upgrade"
    elif command -v dnf >/dev/null 2>&1; then
        package_manager="dnf"
        opts=(-y -q)
        update_cmd="upgrade"
    elif command -v pacman >/dev/null 2>&1; then
        package_manager="pacman"
        opts=(--noconfirm --quiet)
        update_cmd="-Syu"
        install_cmd="-S"
    elif command -v zypper >/dev/null 2>&1; then
        package_manager="zypper"
        opts=(--non-interactive --quiet)
    else
        printf "No supported package manager found.\n\n"
        exit 1
    fi

    # Use the update_cmd as the default value for the upgrade_cmd if not set
    upgrade_cmd="${upgrade_cmd:-$update_cmd}"

    printf "Using %s as package manager and updating...\n\n" "$package_manager"
    sudo "$package_manager" "${opts[@]}" "$update_cmd" >/dev/null
    sudo "$package_manager" "${opts[@]}" "$upgrade_cmd" >/dev/null
    printf "All packages upgraded. Continuing...\n\n"
    printf "Using %s as package manager and installing packages/tools...\n\n" "$package_manager"
    sudo "$package_manager" "${opts[@]}" "$install_cmd" "${package_list[@]}" >/dev/null
    printf "All packages installed. Continuing...\n\n"
}

add_ms_repo() {
    local deb_output=packages-microsoft-prod.deb
    local microsoft_deb
    if [ -e "$deb_output" ]; then
        printf "Microsoft deb found. Continuing...\n\n"
        return 0
    fi
    microsoft_deb=https://packages.microsoft.com/config/ubuntu/"$(lsb_release -rs)"/packages-microsoft-prod.deb
    if output=$(sudo wget -q -O "$deb_output" "$microsoft_deb" 2>&1); then
        printf "Installing powershell dependency. Continuing...\n\n"
        sudo dpkg -i packages-microsoft-prod.deb
    else
        printf "Error occurred: %s\n" "$output"
        exit 1
    fi
    printf "Powershell all set to be installed. Continuing...\n\n"
}

## Setting up brave gpg key
add_brave_repo() {
    printf "Adding Brave GPG key if needed...\n\n"
    local gpg_output=/usr/share/keyrings/brave-browser-archive-keyring.gpg
    if [ -e "$gpg_output" ]; then
        printf "Brave gpg keyring found. Continuing...\n\n"
        return 0
    fi
    local brave_gpg=https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    if output=$(sudo wget -O "$gpg_output" "$brave_gpg" 2>&1); then
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo bash -c 'cat > /etc/apt/sources.list.d/brave-browser-release.list'
    else
        printf "Error occurred: %s\n" "$output"
        exit 1
    fi
    printf "Brave all set to be installed. Continuing...\n\n"
}

# Use Rustup to install Rust stable
install_rust() {
    if ! command -v rustc >/dev/null 2>&1; then
        printf "Installing Rust stable with Rustup...\n\n"
        curl https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain stable -y >/dev/null
        printf "Rust stable installed. Continuing...\n\n"
    fi
    rustup update
    printf "Rust stable updated. Continuing...\n\n"
}

# Installing various cargo tools
# for now just tree-sitter.
install_rust_tools() {
    printf "Installing tree-sitter-cli with Cargo...\n\n"
    # Add Rust to PATH (taken from .cargo/env)
    export PATH="$HOMEDIR/.cargo/bin:$PATH"
    if ! command -v cargo >/dev/null 2>&1; then
        printf "Cargo not found...exiting\n\n"
        exit 1
    fi
    if ! command -v tree-sitter >/dev/null 2>&1; then
        cargo install tree-sitter-cli >/dev/null
        printf "tree-sitter-cli installed \n\n"
    fi
    printf "tree-sitter-cli installed. Continuing...\n\n"
}

# Installing our terminal emulator, wezterm
install_wezterm() {
    local wezterm_version
    local release
    wezterm_version=$(curl -s "https://api.github.com/repos/wez/wezterm/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
    release=$(lsb_release -rs)
    if command -v wezterm >/dev/null 2>&1; then
        installed_version=$(wezterm -V | awk '{print $2}')
        if [ "$installed_version" = "$wezterm_version" ]; then
            printf "Wezterm is installed and up to date. Continuing...\n\n"
            return 0
        fi
    fi
    printf "Installing WezTerm version %s...\n\n" "$wezterm_version"
    if output=$(curl -LO "https://github.com/wez/wezterm/releases/download/${wezterm_version}/wezterm-${wezterm_version}.Ubuntu${release}.deb" 2>&1); then
        sudo apt-get install -yq "./wezterm-${wezterm_version}.Ubuntu${release}.deb" >/dev/null
    else
        printf "Error occured: %s\n" "$output"
    fi
    printf "Wezterm installed. Continuing...\n\n"
}

# Installing Go from source and deleting old copies
install_go() {
    local arch="linux-amd64"
    local go_version
    local go_install_path

    go_version=$(curl -sSL "https://golang.org/VERSION?m=text")
    go_install_path="$HOME/${go_version}.${arch}.tar.gz"

    if command -v go >/dev/null 2>&1 && [[ "$(go version | awk '{print $3}')" == "$go_version" ]]; then
        printf "Go version %s is already installed\n\n" "$go_version"
        return 0
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
}

# Install all recommended Go tools
install_go_tools() {
    printf "Installing/updating Go tools...\n\n"
    if command -v go >/dev/null 2>&1; then
        local go_tools=(
            "github.com/ChimeraCoder/gojson/gojson@latest"
            "github.com/abenz1267/gomvp@latest"
            "github.com/alvaroloes/enumer@latest"
            "github.com/cweill/gotests/gotests@latest"
            "github.com/davidrjenni/reftools/cmd/fillstruct@latest"
            "github.com/fatih/errwrap@latest"
            "github.com/fatih/gomodifytags@latest"
            "github.com/go-delve/delve/cmd/dlv@latest"
            "github.com/godoctor/godoctor@latest"
            "github.com/golang/mock/mockgen@latest"
            "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
            "github.com/jimmyfrasche/closed/cmds/fillswitch@latest"
            "github.com/josharian/impl@latest"
            "github.com/koron/iferr@latest"
            "github.com/kyoh86/richgo@latest"
            "github.com/ofabry/go-callvis@latest"
            "github.com/onsi/ginkgo/ginkgo@latest"
            "github.com/rogpeppe/godef@latest"
            "github.com/searKing/golang/tools/go-enum@latest"
            "github.com/segmentio/golines@latest"
            "github.com/tmc/json-to-struct@latest"
            "github.com/uber/go-torch@latest"
            "golang.org/x/tools/cmd/callgraph@latest"
            "golang.org/x/tools/cmd/goimports@latest"
            "golang.org/x/tools/cmd/gorename@latest"
            "golang.org/x/tools/cmd/guru@latest"
            "golang.org/x/vuln/cmd/govulncheck@latest"
            "gotest.tools/gotestsum@latest"
            "mvdan.cc/gofumpt@latest"
        )

        for tool in "${go_tools[@]}"; do
            printf "Installing/updating %s...\n" "${tool%@*}"
            GO111MODULE=on go install "$tool" >/dev/null
        done
    fi
    printf "Go tools installed/updated. Continuing...\n\n"
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
        git -C "$packer_dir" pull >/dev/null
    else
        git clone --depth 1 "$packer_repo" "$packer_dir" >/dev/null
    fi

    if [ -d "$tpm_dir" ]; then
        git -C "$tpm_dir" pull >/dev/null
    else
        git clone "$tpm_repo" "$tpm_dir" >/dev/null
    fi

    printf "Packer and TPM should be installed! Be sure to run <prefix>+I to install TPM plugins. Continuing...\n\n"
}

# Lazygit makes working with Git in the CLI much nicer, so install it.
install_lazygit() {
    local lazygit_version
    lazygit_version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

    if command -v lazygit >/dev/null 2>&1 && [[ "$lazygit_version" == "$(lazygit -v | grep -oP '(?<=, )version=\K[^,]*')" ]]; then
        printf "Lazygit version %s is already installed\n\n" "$lazygit_version"
        return 0
    fi

    printf "Installing lazygit...\n\n"
    if output=$(curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${lazygit_version}_Linux_x86_64.tar.gz" 2>&1); then
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        printf "Installed Lazygit. Continuing...\n\n"
    else
        printf "Failed cURL'ing lazygit \n\n"
    fi
}

# Lazydocker makes working with Docker in the CLI much nicer, so install it.
install_lazydocker() {
    if command -v lazydocker >/dev/null 2>&1; then
        printf "Lazydocker already installed. Continuing...\n\n"
        return 0
    fi
    printf "Installing Lazydocker...\n\n"
    if output=$(curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash 2>&1); then
        printf "Installed Lazydocker \n\n"
    else
        printf "Error: Failed to install Lazydocker\n\n"
    fi
    printf "Installed Lazydocker. Continuing...\n\n"
}

# I cant write code without vim, apologies
install_neovim() {
    local neovim_repo="https://github.com/neovim/neovim"
    local neovim_dir="$HOMEDIR/neovim-build"

    if command -v nvim >/dev/null 2>&1; then
        installed_version=$(nvim --version | head -n 1 | grep -oP 'NVIM v\K[\d.]+')
        latest_version=$(curl -s https://api.github.com/repos/neovim/neovim/releases/tags/nightly | grep -oP 'NVIM v\K[\d.]+')

        if [ "$installed_version" = "$latest_version" ]; then
            printf "Neovim is already up-to-date. Continuing...\n\n"
            return 0
        fi
    fi

    printf "Installing Neovim...\n\n"

    if [ -d "$neovim_dir" ]; then
        printf "Neovim build directory found, updating...\n\n"
        git -C "$neovim_dir" pull >/dev/null
        rm -rf "$neovim_dir/build" >/dev/null
    else
        printf "Neovim build not directory found, cloning...\n\n"
        git clone --depth 1 "$neovim_repo" "$neovim_dir" >/dev/null
    fi
    printf "Making Neovim...\n\n"
    cd "$neovim_dir" && make CMAKE_BUILD_TYPE=RelWithDebInfo >/dev/null
    printf "Installing Neovim...\n\n"
    sudo make install >/dev/null || {
        printf "Error: failed installing Neovim \n\n"
        exit 1
    }
    printf "Installed Neovim %s. Continuing...\n\n" "$(nvim --version | head -n 1 | awk '{print $2}')"
}

# :checkhealth says I need python I guess
install_neovim_tools() {
    printf "Installing Python-Neovim...\n\n"
    if ! command -v pip3 >/dev/null 2>&1; then
        printf "Pip3 not found...exiting \n\n"
        exit 1
    fi
    if ! command -v npm >/dev/null 2>&1; then
        printf "NPM not found...exiting \n\n"
        exit 1
    fi
    pip3 install neovim >/dev/null
    pip3 install autopep8 >/dev/null
    pip3 install pint >/dev/null
    sudo npm install -g neovim >/dev/null
    sudo npm install -g remark >/dev/null
    cpan -i Neovim::Ext >/dev/null
    sudo gem install neovim >/dev/null
    nvim -c 'TSUpdate' -c 'qa' >/dev/null
    printf "Installed Python-Neovim. Continuing...\n\n"
}

# Change the hostname to whatever was set
set_hostname() {
    if [ "$HOSTNAME" == "" ]; then
        printf "Skipping hostname config...\n\n"
        return 0
    fi
    sudo su -c "echo '$HOSTNAME' > /etc/hostname"
    export HOST=$HOSTNAME
    printf "Hostname set to %s. Continuing...\n\n" "$HOSTNAME"
}

# Configure local git
config_git() {
    if [ "$GIT_EMAIL" == "" ] || [ "$GIT_USER" == "" ]; then
        printf "Skipping git config...\n\n"
        return 0
    fi
    git config --global user.email "$GIT_EMAIL"
    git config --global user.name "$GIT_USER"
    printf "Git configured to use %s as email and %s as user. Continuing...\n\n" "$GIT_EMAIL" "$GIT_USER"
}

# Use systemd to start and enable ssh so we can connect
start_enable_ssh() {
    # Check if the service is enabled
    if ! systemctl is-enabled ssh >/dev/null 2>&1; then
        sudo systemctl enable ssh >/dev/null 2>&1
    fi

    # Check if the service is started (active)
    if ! systemctl is-active ssh >/dev/null 2>&1; then
        sudo systemctl start ssh >/dev/null 2>&1
    fi

    printf "SSH started and enabled. Continuing...\n\n"
}

install_composer() {
    if ! command -v composer >/dev/null 2>&1; then
        curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
    fi
}

# Take the personal token that was made, auth with it, and add the ssh key
# Necessary since we use git submodules with SSH
setup_github() {
    if [ "$GH_PERSONAL_TOKEN" == "" ]; then
        printf "Skipping GH auth...\n\n"
        return 0
    fi
    printf "Setting up GitHub...\n\n"

    if ! gh auth status >/dev/null 2>&1; then
        printf "Adding Token %s \n\n" "$GH_PERSONAL_TOKEN"
        gh auth login --with-token <<<"$GH_PERSONAL_TOKEN"
    fi

    if [ ! -f "$HOME/.ssh/github" ]; then
        # Make new ssh key for gh
        printf "Creating ssh key for GitHub for %s...\n\n" "$HOST"
        ssh-keygen -f ~/.ssh/github -N ""
        printf "Adding ssh key to github\n\n"
        gh ssh-key add "$HOMEDIR/.ssh/github.pub" --title "$HOST"
    fi
    printf "GitHub setup finished. Continuing...\n\n"
}

# Heres the meat and potatoes, our bare repo will be unpacked
setup_git_repo() {
    printf "Setting up Git repo \n\n"
    local dotfiles_repo="https://github.com/linkinlog/.dotfiles"
    local dotfiles_dir="$HOMEDIR/.dotfiles.git"
    local config_cmd="git --git-dir=$dotfiles_dir --work-tree=$HOMEDIR"

    if [ ! -d "$dotfiles_dir" ]; then
        git clone --bare "$dotfiles_repo" >/dev/null
        eval "$config_cmd" checkout >/dev/null
    fi

    eval "$config_cmd" fetch origin development >/dev/null
    eval "$config_cmd" merge development >/dev/null
    eval "$config_cmd" config --local status.showUntrackedFiles no
    printf "Setting up bare repo's submodules \n\n"
    GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no' eval "$config_cmd" submodule update --init --remote >/dev/null
    printf "Installing our neovim plugins\n\n"
    nvim -c 'PackerSync' -c 'autocmd User PackerComplete qa'
    printf "dotfiles repo setup finished. Continuing...\n\n"
}

# Mainly just for the theme, hoping to phase out at some point
setup_ohmyzsh() {
    printf "Setting up OhMyZsh\n\n"

    if [ ! -d "$HOMEDIR/.oh-my-zsh" ]; then
        export RUNZSH=no
        export KEEP_ZSHRC=yes
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            "" --unattended || {
            printf "Error: could not install OhMyZsh \n\n"
            exit 1
        }
        sudo chsh -s "$(which zsh)" -u "$(whoami)"
    else
        git -C "$HOMEDIR/.oh-my-zsh" pull >/dev/null
    fi

    local zsh_syntax_highlighting_path="${ZSH_CUSTOM:-$HOMEDIR/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    if [ -d "$zsh_syntax_highlighting_path" ]; then
        git -C "$zsh_syntax_highlighting_path" pull >/dev/null
    else
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_syntax_highlighting_path" || {
            printf "Error: could not clone zsh-syntax-highlighting \n\n"
            exit 1
        } >/dev/null
    fi

    local zsh_autosuggestions_path="${ZSH_CUSTOM:-$HOMEDIR/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [ -d "$zsh_autosuggestions_path" ]; then
        git -C "$zsh_autosuggestions_path" pull >/dev/null
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_autosuggestions_path" || {
            printf "Error: could not clone zsh-autosuggestions \n\n"
            exit 1
        } >/dev/null
    fi
    printf "OhMyZsh, zsh-syntax-highlighting, and zsh-autosuggestions installed. Continuing...\n\n"
}

# Group the dependency commands together
install_dependencies() {
    add_brave_repo
    add_ms_repo
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
    (install_composer)
    (install_lazydocker)
    (install_lazygit)
    refresh_sudo
    (install_neovim)
    (install_neovim_tools)
    (install_rust)
    refresh_sudo
    (install_rust_tools)
    (install_terminal_tools)
    (setup_github)
    (setup_git_repo)
    refresh_sudo
    (install_wezterm)
    (setup_ohmyzsh)
}

# Run it all and only care about STDERR
main() {
    cd "$HOME"
    install_dependencies
    configure_environment
    printf "Should be all set, good luck!!\n"
}

main "$@"
