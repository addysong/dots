# My Dotfiles

This directory contains most of my dotfiles. Some are cross-platform, and others are exclusive to certain software on Linux only. Software that have more complex configuration file structures are separated into separate repos that will be linked below. Some additional changes that are not stored any repos (usually due to using GUI configuration or living somewhere outside of the home directory) are noted.

## Installation

1. Clone this repo into your home directory.
2. Add any files/directories you don't want included into a `sync-exclude` file in this repo.
3. Run `./dotsync`.

If any config files already exist on the machine, there are two options to resolve conflicts:

1. Run with the `--adopt` flag to "adopt" any conflicting files into the `dots` directory and replace them with the files on the current machine.
2. Remove conflicting files from the `~/` non-dots directory.

## Separated config repos

- Neovim: <https://github.com/AddysonG/nvim>
- VSCode: <https://github.com/AddysonG/vscode>

## Theming

- I use Breeze dark theme as a default for GTK and QT apps. There are packages for these, some of which need to be installed through the AUR on Arch.
- I use Papirus icon theme. Again, there are packages for this.

```
# Official repos
breeze breeze5 breeze-gtk papirus-icon-theme qt5ct qt6ct noto-fonts noto-fonts-cjk

# AUR
catppuccin-cursors-mocha
```

## IME

I use fcitx5 with some settings changed.

## Network manager

If on Arch, add `NetworkManager` as an additional package and do NOT carry over the configuration from the install script if using it, as doing so will require extra changes to switch the network manager.

## Claude Code

To set up integration with Herdr, launch Claude Code at least once, then:

```sh
herdr integration install claude
```

This write a `SessionStart` hook into `.claude/settings.json` as part of the setup process. Try to avoid adding that hook when committing.
