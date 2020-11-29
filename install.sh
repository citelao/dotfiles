#!/usr/bin/env zsh

# Install citelao's dotfiles!
#
# Remove existing stuff:
# FORCE=true ./install.sh

# Debug?
# set -x

set -u

SCRIPT_DIR=$(dirname "$0")
pushd $SCRIPT_DIR
FULL_SCRIPT_DIR=$(pwd)
popd

# String formatters
# stolen from Homebrew
# https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

# Link a file!
# 
# Usage:
# > deploy_file source dest
function deploy_file()
{
    source=$1
    dest=$2

    if [[ "${FORCE-}" = true ]]; then
        echo "Removing existing ${tty_red}$dest${tty_reset}"
        rm $dest
    fi

    echo "Deploying ${tty_blue}$source${tty_reset} to ${tty_blue}$dest${tty_reset}"
    ln -s $source $dest
}


deploy_file "${FULL_SCRIPT_DIR}/.zshrc" ~/.zshrc
# $ZSH_CUSTOM = .oh-my-zsh
deploy_file "${FULL_SCRIPT_DIR}/citelao.zsh-theme" ~/.oh-my-zsh/themes/citelao.zsh-theme