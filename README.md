# dotfiles

## Installation

On a fresh install:

```bash
sudo softwareupdate -i -a
xcode-select --install
```

The Xcode Command Line Tools includes git and make (not available on stock macOS).

```bash
git clone https://github.com/jgiovaresco/dotfiles.git ~/.dotfiles
```

Use the [Makefile](./Makefile) to install everything.

```bash
cd ~/.dotfiles
make
```
