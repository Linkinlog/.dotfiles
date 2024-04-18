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
readonly DEPS=("ninja-build" "gettext" "libtool-bin" "cmake" "g++" "pkg-config" "unzip" "curl" "python3" "python3-pip" "bsdutils" "cmake" "dpkg-dev" "fakeroot" "gcc" "g++" "libegl1-mesa-dev" "libssl-dev" "libfontconfig1-dev" "libwayland-dev" "libx11-xcb-dev" "libxcb-ewmh-dev" "libxcb-icccm4-dev" "libxcb-image0-dev" "libxcb-keysyms1-dev" "libxcb-randr0-dev" "libxcb-render0-dev" "libxcb-xkb-dev" "libxkbcommon-dev" "libxkbcommon-x11-dev" "libxcb-util0-dev" "lsb-release" "python3" "xdg-utils" "xorg-dev" "luarocks" "ruby" "ruby-dev" "php" "npm" "php-zip" "unzip" "openjdk-11-jdk" "powershell" "wget" "apt-transport-https" "software-properties-common")

# Ensure all dependencies are here after installation
check_dependencies() {
    printf "\r\e[K\e[34m🛠️ Checking dependencies...\e[0m"
    if ! git --version >/dev/null 2>&1; then
        printf "\r\e[K\e[31m❌ Git is not installed. Please install Git and try again. Exiting... \e[0m"
        exit 1
    fi

    if ! curl --version >/dev/null 2>&1; then
        printf "\r\e[K\e[31m❌ Curl is not installed. Please install Curl and try again. Exiting... \e[0m"
        exit 1
    fi

    if ! wget --version >/dev/null 2>&1; then
        printf "\r\e[K\e[31m❌ Wget is not installed. Please install Wget and try again. Exiting... \e[0m"
        exit 1
    fi

    if ! unzip -v >/dev/null 2>&1; then
        printf "\r\e[K\e[31m❌ Unzip is not installed. Please install Unzip and try again. Exiting... \e[0m"
        exit 1
    fi

    if ! dpkg -s build-essential >/dev/null 2>&1; then
        printf "\r\e[K\e[31m❌ Build-essential is not installed. Please install Build-essential and try again. Exiting... \e[0m"
        exit 1
    fi
    printf "\r\e[K\e[32m✅ All dependencies set. Continuing...\e[0m"
}

# Refresh sudo auth so we can ask for password less
refresh_sudo() {
    printf "\r\e[K\e[34m🛠️ Refreshing sudo authentication... \e[0m"
    sudo -v
}

# Installs whatever package list is passed in
# @param Array package_list
install_packages() {
    local package_manager opts
    local update_cmd="update"
    local install_cmd="install"
    local package_list=("$@")

    printf "\r\e[K\e[34m🛠️ Determining package manager... \e[0m"
    if command -v apt-get >/dev/null 2>&1; then
        package_manager="apt-get"
        opts=(-y -qq)
        update_cmd="upgrade"
        sudo "$package_manager" update "${opts[@]}"
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
        printf "\r\e[K\e[31m❌ No supported package manager found. Exiting... \e[0m"
        exit 1
    fi

    printf "\r\e[K\e[34m🛠️ Using %s as package manager and updating...\e[0m" "$package_manager"
    sudo "$package_manager" "${opts[@]}" "$update_cmd"
    sudo "$package_manager" "${opts[@]}" "$install_cmd" "${package_list[@]}"
    printf "\r\e[K\e[32m✅ All packages installed. Continuing...\e[0m"
}

add_ms_repo() {
    local deb_output=packages-microsoft-prod.deb
    local microsoft_deb
    if [ -e "$deb_output" ]; then
        printf "\r\e[K\e[32m✅ Microsoft deb found. Continuing...\e[0m"
        return 0
    fi
    microsoft_deb=https://packages.microsoft.com/config/ubuntu/"$(lsb_release -rs)"/packages-microsoft-prod.deb
    if output=$(sudo wget -q -O "$deb_output" "$microsoft_deb" 2>&1); then
        printf "\r\e[K\e[32m✅ Installing powershell dependency. Continuing...\e[0m"
        sudo dpkg -i packages-microsoft-prod.deb
    else
        printf "\r\e[K\e[31m❌ Error occurred: %s Exiting... \e[0m" "$output"
        exit 1
    fi
    printf "\r\e[K\e[32m✅ Powershell all set to be installed. Continuing...\e[0m"
}

## Setting up brave gpg key
add_brave_repo() {
    printf "\r\e[K\e[34m🛠️ Adding Brave GPG key if needed...\e[0m"
    local gpg_output=/usr/share/keyrings/brave-browser-archive-keyring.gpg
    if [ -e "$gpg_output" ]; then
        printf "\r\e[K\e[32m✅ Brave gpg keyring found. Continuing...\e[0m"
        return 0
    fi
    local brave_gpg=https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    if output=$(sudo wget -O "$gpg_output" "$brave_gpg" 2>&1); then
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo bash -c 'cat > /etc/apt/sources.list.d/brave-browser-release.list'
    else
        printf "\r\e[K\e[31m❌ Error occurred: %s Exiting... \e[0m" "$output"
        exit 1
    fi
    printf "\r\e[K\e[32m✅ Brave all set to be installed. Continuing...\e[0m"
}

# Use Rustup to install Rust stable
install_rust() {
    # Allows a user to set the profile/toolchain they want
    local profile="${RUST_PROFILE:-minimal}"
    local toolchain="${RUST_TOOLCHAIN:-stable}"
    if ! command -v rustc >/dev/null 2>&1; then
        printf "\r\e[K\e[34m🛠️ Installing Rust stable with Rustup...\e[0m"
        curl https://sh.rustup.rs -sSf | sh -s -- --profile "$profile" --default-toolchain "$toolchain" -y 
        printf "\r\e[K\e[32m✅ Rust stable installed. Continuing...\e[0m"
    fi
    rustup default "$toolchain" 2>&1
    rustup update >/dev/null 2>&1
    printf "\r\e[K\e[32m✅ Rust stable updated. Continuing...\e[0m"
}

# Installing various cargo tools
# for now just tree-sitter.
install_rust_tools() {
    printf "\r\e[K\e[34m🛠️ Installing tree-sitter-cli with Cargo...\e[0m"
    # Add Rust to PATH (taken from .cargo/env)
    export PATH="$HOMEDIR/.cargo/bin:$PATH"
    if ! command -v cargo >/dev/null 2>&1; then
        printf "\r\e[K\e[31m❌ Cargo not found. Exiting... \e[0m"
        exit 1
    fi
    if ! command -v tree-sitter >/dev/null 2>&1; then
        cargo install -q tree-sitter-cli >/dev/null
    fi
    printf "\r\e[K\e[32m✅ Tree-sitter-cli installed. Continuing...\e[0m"
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
            printf "\r\e[K\e[32m✅ Wezterm is installed and up to date. Continuing...\e[0m"
            return 0
        fi
    fi
    printf "\r\e[K\e[34m🛠️ Installing WezTerm version %s...\e[0m" "$wezterm_version"
    if output=$(curl -LO "https://github.com/wez/wezterm/releases/download/${wezterm_version}/wezterm-${wezterm_version}.Ubuntu${release}.deb" 2>&1); then
        sudo apt-get install -yq "./wezterm-${wezterm_version}.Ubuntu${release}.deb" >/dev/null
    else
        printf "\r\e[K\e[31m❌ Error occured: %s Exiting... \e[0m" "$output"
    fi
    printf "\r\e[K\e[32m✅ Wezterm installed. Continuing...\e[0m"
}

# Installing Go from source and deleting old copies
install_go() {
    local arch="linux-amd64"
    local go_version
    local go_install_path

    go_version="go1.21.0"
    go_install_path="$HOME/${go_version}.${arch}.tar.gz"

    if command -v go >/dev/null 2>&1 && [[ "$(go version | awk '{print $3}')" == "$go_version" ]]; then
        printf "\r\e[K\e[32m✅ Go version %s is already installed. Continuing... \e[0m" "$go_version"
        return 0
    fi

    if output=$(sudo wget -O "$go_install_path" "https://go.dev/dl/${go_version}.${arch}.tar.gz" 2>&1); then
        printf "\r\e[K\e[34m🛠️ Installing Go version %s to %s... \e[0m" "$go_version" "$go_install_path"
        [ -f /usr/local/bin/go ] && sudo rm /usr/local/bin/go
        [ -f /usr/local/go ] && sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "${go_version}.${arch}.tar.gz" >/dev/null
        sudo ln -s /usr/local/go/bin/go /usr/local/bin/go
    else
        printf "\r\e[K\e[31m❌ Error occurred: %s. Exiting... \e[0m" "$output"
        exit 1
    fi
    printf "\r\e[K\e[32m✅ Go installed. Continuing...\e[0m"
}

# Install all recommended Go tools
install_go_tools() {
    printf "\r\e[K\e[34m🛠️ Installing/updating Go tools...\e[0m"
    if ! command -v go >/dev/null 2>&1; then
        printf "\r\e[K\e[31m❌ Error occurred: go not found. Exiting... \e[0m"
        return 1
    fi
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
        exec_name=$(basename "${tool%@*}")
        if ! type "$exec_name" >/dev/null 2>&1; then
            printf "\r\e[K\e[34m🛠️ Installing/updating %s...\e[0m" "${tool%@*}"
            GO111MODULE=on go install "$tool" >/dev/null
        fi
    done
    printf "\r\e[K\e[32m✅ Go tools installed/updated. Continuing...\e[0m"
}

# We use packer for plugin management in Neovim, so install that.
# We use TPM for plugin management in Tmux, so install that.
install_terminal_tools() {
    local packer_repo="https://github.com/wbthomason/packer.nvim"
    local packer_dir="$HOMEDIR/.local/share/nvim/site/pack/packer/start/packer.neovim"
    local tpm_repo="https://github.com/tmux-plugins/tpm"
    local tpm_dir="$HOMEDIR/.tmux/plugins/tpm"

    printf "\r\e[K\e[34m🛠️ Installing TPM and Packer...\e[0m"

    if [ -d "$packer_dir" ]; then
        git -C "$packer_dir" pull -q >/dev/null
    else
        git clone -q --depth 1 "$packer_repo" "$packer_dir" >/dev/null
    fi

    if [ -d "$tpm_dir" ]; then
        git -C "$tpm_dir" pull -q >/dev/null
    else
        git clone -q "$tpm_repo" "$tpm_dir" >/dev/null
    fi

    printf "\r\e[K\e[32m✅ Packer and TPM should be installed! \e[33mBe sure to run <prefix>+I to install TPM plugins.\e[32m Continuing...\e[0m"
}

# Lazygit makes working with Git in the CLI much nicer, so install it.
install_lazygit() {
    local lazygit_version
    lazygit_version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

    if command -v lazygit >/dev/null 2>&1 && [[ "$lazygit_version" == "$(lazygit -v | grep -oP '(?<=, )version=\K[^,]*')" ]]; then
        printf "\r\e[K\e[32m✅ Lazygit version %s is already installed. Continuing... \e[0m" "$lazygit_version"
        return 0
    fi

    printf "\r\e[K\e[34m🛠️ Installing lazygit...\e[0m"
    if output=$(curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${lazygit_version}_Linux_x86_64.tar.gz" 2>&1); then
        tar xf lazygit.tar.gz lazygit >/dev/null
        sudo install lazygit /usr/local/bin >/dev/null
        printf "\r\e[K\e[32m✅ Installed Lazygit. Continuing...\e[0m"
    else
        printf "\r\e[K\e[31m❌ Failed cURL'ing lazygit. Exiting... \e[0m"
        return 1
    fi
}

# Lazydocker makes working with Docker in the CLI much nicer, so install it.
install_lazydocker() {
    if command -v lazydocker >/dev/null 2>&1; then
        printf "\r\e[K\e[32m✅ Lazydocker already installed. Continuing...\e[0m"
        return 0
    fi
    printf "\r\e[K\e[34m🛠️ Installing Lazydocker...\e[0m"
    if output=$(curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash 2>&1); then
        printf "\r\e[K\e[32m✅ Installed Lazydocker. Continuing... \e[0m"
    else
        printf "\r\e[K\e[32m✅ Error: Failed to install Lazydocker. Continuing... \e[0m"
    fi
    printf "\r\e[K\e[32m✅ Installed Lazydocker. Continuing...\e[0m"
}

# I cant write code without vim, apologies
install_neovim() {
    local neovim_repo="https://github.com/neovim/neovim"
    local neovim_dir="$HOMEDIR/neovim-build"

    if command -v nvim >/dev/null 2>&1; then
        installed_version=$(nvim --version | head -n 1 | grep -oP 'NVIM v\K[\d.]+')
        latest_version=$(curl -s https://api.github.com/repos/neovim/neovim/releases/tags/nightly | grep -oP 'NVIM v\K[\d.]+')

        if [ "$installed_version" = "$latest_version" ]; then
            printf "\r\e[K\e[32m✅ Neovim is already up-to-date. Continuing...\e[0m"
            return 0
        fi
    fi

    printf "\r\e[K\e[34m🛠️ Installing Neovim...\e[0m"

    if [ -d "$neovim_dir" ]; then
        printf "\r\e[K\e[34m🛠️ Neovim build directory found, updating...\e[0m"
        git -C "$neovim_dir" pull -q >/dev/null
        [ -f "$neovim_dir/build" ] && rm -rf "$neovim_dir/build" >/dev/null
    else
        printf "\r\e[K\e[34m🛠️ Neovim build not directory found, cloning...\e[0m"
        git clone -q --depth 1 "$neovim_repo" "$neovim_dir" >/dev/null
    fi
    printf "\r\e[K\e[34m🛠️ Making Neovim...\e[0m"
    cd "$neovim_dir" && make CMAKE_BUILD_TYPE=RelWithDebInfo >/dev/null
    printf "\r\e[K\e[34m🛠️ Installing Neovim...\e[0m"
    sudo make install >/dev/null || {
        printf "\r\e[K\e[31m❌ Error: failed installing Neovim. Exiting... \e[0m"
        return 1
    }
    nvim -c 'TSUpdate' -c 'qa' >/dev/null
    printf "\r\e[K\e[32m✅ Installed Neovim %s. Continuing...\e[0m" "$(nvim --version | head -n 1 | awk '{print $2}')"
}

# Tools provided by pip/npm
install_neovim_tools() {
    if pip3 list 2>/dev/null | grep -q neovim; then
        printf "\r\e[K\e[32m✅ Neovim is installed with pip3. Continuing...\e[0m"
    else
        pip3 install neovim >/dev/null
    fi

    if pip3 list 2>/dev/null | grep -q autopep8; then
        printf "\r\e[K\e[32m✅ Autopep8 is installed with pip3. Continuing... \e[0m"
    else
        pip3 install autopep8 >/dev/null
    fi

    if npm list -g --depth=0 2>/dev/null | grep -q remark; then
        printf "\r\e[K\e[32m✅ Remark is installed globally with npm. Continuing...\e[0m"
    else
        sudo npm install -g remark >/dev/null
    fi

    if npm list -g --depth=0 2>/dev/null | grep -q neovim; then
        printf "\r\e[K\e[32m✅ Neovim is installed globally with npm. Continuing...\e[0m"
    else
        sudo npm install -g neovim >/dev/null
    fi

    if gem list -i neovim >/dev/null 2>&1; then
        printf "\r\e[K\e[32m✅ Neovim is installed with gem. Continuing...\e[0m"
    else
        sudo gem install neovim >/dev/null
    fi
}

# Change the hostname to whatever was set
set_hostname() {
    if [ "$HOSTNAME" == "" ]; then
        printf "\r\e[K\e[34m🛠️ Skipping hostname config...\e[0m"
        return 0
    fi
    sudo su -c "echo '$HOSTNAME' > /etc/hostname"
    export HOST=$HOSTNAME
    printf "\r\e[K\e[32m✅ Hostname set to %s. Continuing...\e[0m" "$HOSTNAME"
}

# Configure local git
config_git() {
    if [ "$GIT_EMAIL" == "" ] || [ "$GIT_USER" == "" ]; then
        printf "\r\e[K\e[34m🛠️ Skipping git config...\e[0m"
        return 0
    fi
    git config --global user.email "$GIT_EMAIL"
    git config --global user.name "$GIT_USER"
    git config --global core.excludesfile ~/.gitignore
    printf "\r\e[K\e[32m✅ Git configured to use %s as email and %s as user. Continuing...\e[0m" "$GIT_EMAIL" "$GIT_USER"
}

# Use systemd to start and enable ssh so we can connect
start_enable_ssh() {
    # Check if the service is enabled
    printf "\r\e[K\e[34m🛠️ Starting and enabling SSH...\e[0m"
    if ! systemctl is-enabled ssh >/dev/null 2>&1; then
        sudo systemctl enable ssh >/dev/null 2>&1
    fi

    # Check if the service is started (active)
    if ! systemctl is-active ssh >/dev/null 2>&1; then
        sudo systemctl start ssh >/dev/null 2>&1
    fi

    printf "\r\e[K\e[32m✅ SSH started and enabled. Continuing...\e[0m"
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
        printf "\r\e[K\e[34m🛠️ Skipping GH auth...\e[0m"
        return 0
    fi
    printf "\r\e[K\e[34m🛠️ Setting up GitHub...\e[0m"

    if ! gh auth status >/dev/null 2>&1; then
        printf "\r\e[K\e[34m🛠️ Adding Token %s... \e[0m" "$GH_PERSONAL_TOKEN"
        gh auth login --with-token <<<"$GH_PERSONAL_TOKEN"
    fi

    if [ ! -f "$HOME/.ssh/github" ]; then
        # Make new ssh key for gh
        printf "\r\e[K\e[34m🛠️ Creating ssh key for GitHub for %s...\e[0m" "$HOST"
        ssh-keygen -f ~/.ssh/github -N ""
        printf "\r\e[K\e[34m🛠️ Adding ssh key to github... \e[0m"
        gh ssh-key add "$HOMEDIR/.ssh/github.pub" --title "$HOST"
    fi
    printf "\r\e[K\e[32m✅ GitHub setup finished. Continuing...\e[0m"
}

# Heres the meat and potatoes, our bare repo will be unpacked
setup_git_repo() {
    printf "\r\e[K\e[34m🛠️ Setting up Git repo... \e[0m"
    local dotfiles_repo="https://github.com/linkinlog/.dotfiles"
    local dotfiles_dir="$HOMEDIR/.dotfiles.git"
    local config_cmd="git --git-dir=$dotfiles_dir --work-tree=$HOMEDIR"

    if [ ! -d "$dotfiles_dir" ]; then
        git clone --bare "$dotfiles_repo" >/dev/null
        eval "$config_cmd" checkout >/dev/null
    fi

    eval "$config_cmd" fetch -q origin development >/dev/null
    eval "$config_cmd" merge -q development >/dev/null
    eval "$config_cmd" config --local status.showUntrackedFiles no
    eval "$config_cmd" config --global submodule.recurse true
    printf "\r\e[K\e[34m🛠️ Setting up bare repo's submodules... \e[0m"
    GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no' eval "$config_cmd" submodule update --init --remote >/dev/null
    printf "\r\e[K\e[34m🛠️ Installing our neovim plugins... \e[0m"
    nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
    printf "\r\e[K\e[32m✅ Dotfiles repo setup finished. Continuing...\e[0m"
}

# Mainly just for the theme, hoping to phase out at some point
setup_ohmyzsh() {
    printf "\r\e[K\e[34m🛠️ Setting up OhMyZsh... \e[0m"

    if [ ! -d "$HOMEDIR/.oh-my-zsh" ]; then
        export RUNZSH=no
        export KEEP_ZSHRC=yes
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            "" --unattended || {
            printf "\r\e[K\e[31m❌ Error: could not install OhMyZsh. Exiting... \e[0m"
            exit 1
        }
        sudo chsh -s "$(which zsh)" -u "$(whoami)"
    else
        git -C "$HOMEDIR/.oh-my-zsh" pull -q >/dev/null
    fi

    local zsh_syntax_highlighting_path="${ZSH_CUSTOM:-$HOMEDIR/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    if [ -d "$zsh_syntax_highlighting_path" ]; then
        git -C "$zsh_syntax_highlighting_path" pull -q >/dev/null
    else
        git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_syntax_highlighting_path" || {
            printf "\r\e[K\e[31m❌ Error: could not clone zsh-syntax-highlighting Exiting... \e[0m"
            exit 1
        } >/dev/null
    fi

    local zsh_autosuggestions_path="${ZSH_CUSTOM:-$HOMEDIR/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [ -d "$zsh_autosuggestions_path" ]; then
        git -C "$zsh_autosuggestions_path" pull -q >/dev/null
    else
        git clone -q https://github.com/zsh-users/zsh-autosuggestions "$zsh_autosuggestions_path" || {
            printf "\r\e[K\e[31m❌ Error: could not clone zsh-autosuggestions Exiting... \e[0m"
            exit 1
        } >/dev/null
    fi
    printf "\r\e[K\e[32m✅ OhMyZsh, zsh-syntax-highlighting, and zsh-autosuggestions installed. Continuing...\e[0m"
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
    printf "\r\e[K\e[32m✅ Should be all set, good luck!!\n\e[0m"
}

main "$@"
