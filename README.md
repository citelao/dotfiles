# Dotfiles

Citelao's personal dotfiles! What a treat!

## Install

### macOS

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

### Windows

```pwsh
winget install twpayne.chezmoi
chezmoi init https://github.com/citelao/dotfiles2.git
chezmoi apply
```

You may also want:

```pwsh
Install-Module ZLocation -Scope CurrentUser
& ([scriptblock]::Create((iwr 'https://to.loredo.me/Install-NerdFont.ps1'))) -Name hack

winget install -e junegunn.fzf
```

## Editing

```pwsh
chezmoi cd
c .

# Commit
# git add, etc
git push
```

## TODO

* [ ] `.gitconfig`?

## See also

https://github.com/citelao/dotfiles2