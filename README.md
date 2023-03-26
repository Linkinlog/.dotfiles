# Are you looking for a highly opinionated, pre-configured, and barely stable local development configuration?
Well, then you're in luck! Here is my `.dotfiles` repo where I have my automated development setup script located in `.local/bin/setup.sh` and all my configurations in `.config`.

Welcome to my *highly opinionated* dotfiles repository, where I've managed to take the **pain** out of setting up your local development environment... and shifted it right onto your shoulders! That's right! Now you too can feel the joy of using a system that's built around Neovim, Zsh, and Tmux. Don't know what those are? Don't worry, neither do I!

## What you get
- Neovim (with some totally essential plugins, trust me)
- Zsh (with oh-my-zsh)
- Tmux (with tpm)
- Tools for Rust and Go
- A bunch of other terminal goodies (like Lazydocker, Lazygit, WezTerm, and more!)
So, if you're a die-hard Ubuntu/Debian fan, or you just don't care about your own sanity, keep reading!

## Prerequisites
- Ubuntu or Debian-based distributions (for now)
- A burning desire to throw caution to the wind
- A github personal accesss token: [read more](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
  - Needs `admin:public_key, read:org, repo` access

## Installation
To get started, just run the install script with the following command:
```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/linkinlog/.dotfiles/master/.local/bin/setup.sh)" -- <hostname> <git_email> <git_user> <gh_personal_token>
```
Replace `<hostname>`, `<git_email>`, `<git_user>`, and `<gh_personal_token>` with your desired hostname, Git email, Git username, and GitHub personal token, respectively.

Be sure to source the packer file with `:source $HOME/.config/nvim/lua/thelogger/packer.lua` and then run `:PackerSync` in Neovim and `<prefix>+I` in Tmux to install the necessary plugins.


## Warning
This script has been *carefully crafted* to work on Ubuntu/Debian-based distributions. If you're a fan of other distributions, you might want to give this a pass... or better yet, submit a PR and join the madness!

## One last thing
Remember, this is *highly opinionated*, so things might not work exactly how you expect. But, hey, that's half the fun, right?

## Contributing
If you think you can make this chaos even better, feel free to open an issue or submit a PR. Just remember, there's a fine line between genius and insanity. Are you up for the challenge?

Happy hacking!
