# Dotfiles

Citelao's personal dotfiles

## Install

```bash
brew install chezmoi
chezmoi init https://github.com/citelao/dotfiles
chezmoi apply
```

You may also want to install useful tools:

```bash
# https://ohmyz.sh/#install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Github CLI
# https://cli.github.com
brew install gh
# gh auth login

# https://github.com/junegunn/fzf?tab=readme-ov-file#using-homebrew
brew install fzf

# https://github.com/ajeetdsouza/zoxide
# https://github.com/ajeetdsouza/zoxide?tab=readme-ov-file#installation
brew install zoxide

# https://github.com/source-foundry/Hack
brew install --cask font-hack
```

## Terminal plist workflow

`dotfiles/private_Library/private_Preferences/private_com.apple.Terminal.plist` is tracked as an XML plist so Terminal preference changes diff cleanly in git.

- `chezmoi apply` writes the tracked plist to `~/Library/Preferences/com.apple.Terminal.plist`, and the onchange hook converts it to binary before running `defaults import`.
- `contrib/terminal-plist.sh export` converts the live `~/Library/Preferences/com.apple.Terminal.plist` back to XML and writes it into the repo.
- `contrib/terminal-plist.sh import` imports the tracked XML plist into the Terminal defaults domain without a full `chezmoi apply`.

## See also

https://github.com/citelao/dotfiles2