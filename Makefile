SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos)
PATH := $(DOTFILES_DIR)/bin:$(PATH)
NVM_DIR := $(HOME)/.nvm
export XDG_CONFIG_HOME := $(HOME)/.config
export STOW_DIR := $(DOTFILES_DIR)

.PHONY: test

all: $(OS)

macos: sudo core-macos keylayout packages link

core-macos: brew zsh git npm

stow-macos: brew
	is-executable stow || brew install stow

sudo:
ifndef GITHUB_ACTION
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

packages: brew-packages cask-apps

link: stow-$(OS)
	for FILE in $$(\ls -A myshell); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
		mv -v $(HOME)/$$FILE{,.bak}; fi; done
	mkdir -p $(XDG_CONFIG_HOME)
	stow -t $(HOME) myshell
	stow -t $(XDG_CONFIG_HOME) config

unlink: stow-$(OS)
	stow --delete -t $(HOME) myshell
	stow --delete -t $(XDG_CONFIG_HOME) config
	for FILE in $$(\ls -A myshell); do if [ -f $(HOME)/$$FILE.bak ]; then \
		mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; fi; done

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

zsh: ZSH=/usr/local/bin/zsh
zsh: SHELLS=/private/etc/shells
zsh: brew
ifdef GITHUB_ACTION
	if ! grep -q $(ZSH) $(SHELLS); then \
		brew install zsh && \
		sudo chsh -s $(ZSH); \
	fi
else
	if ! grep -q $(ZSH) $(SHELLS); then \
		brew install zsh && \
		chsh -s $(ZSH); \
	fi
endif

git: brew
	brew install git git-extras

npm:
	if ! [ -d $(NVM_DIR)/.git ]; then git clone https://github.com/creationix/nvm.git $(NVM_DIR); fi
	. $(NVM_DIR)/nvm.sh; nvm install --lts

brew-packages: brew clean-python
	brew bundle --file=$(DOTFILES_DIR)/macos/install/Brewfile

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/macos/install/Caskfile || true
	xattr -d -r com.apple.quarantine ~/Library/QuickLook

test:
	. $(NVM_DIR)/nvm.sh; bats test

clean-python:
	rm -f '/usr/local/bin/2to3'

keylayout:
	cd ~/Library/Keyboard\ Layouts/ && \
	curl https://qwerty-lafayette.org/releases/lafayette_macosx_v0.6.keylayout --output lafayette_macosx.keylayout
