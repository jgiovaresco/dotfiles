SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos)
PATH := $(DOTFILES_DIR)/bin:$(PATH)
NVM_DIR := $(HOME)/.nvm
RVM_DIR := $(HOME)/.rvm
OMZSH_DIR := $(HOME)/.oh-my-zsh
ZSH_CUSTOM := $(OMZSH_DIR)/custom
TMUX_DIR := $(HOME)/.tmux

JENV_DIR := $(HOME)/.jenv

export XDG_CONFIG_HOME := $(HOME)/.config
export STOW_DIR := $(DOTFILES_DIR)

.PHONY: test

all: $(OS)

macos: sudo core-macos keylayout packages link

core-macos: brew zsh oh-my-zsh git npm rvm tmux

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

zsh: ZSH=/bin/zsh
zsh: SHELLS=/etc/shells
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

oh-my-zsh: zsh
	if ! [ -d $(OMZSH_DIR)/.git ]; then git clone https://github.com/ohmyzsh/ohmyzsh.git $(OMZSH_DIR); fi
	if ! [ -d $(ZSH_CUSTOM)/plugins/zsh-syntax-highlighting/.git ]; then git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $(ZSH_CUSTOM)/plugins/zsh-syntax-highlighting; fi
	if ! [ -d $(ZSH_CUSTOM)/plugins/zsh-autosuggestions/.git ]; then git clone https://github.com/zsh-users/zsh-autosuggestions $(ZSH_CUSTOM)/plugins/zsh-autosuggestions; fi

git: brew
	brew install git git-extras

npm:
	if ! [ -d $(NVM_DIR)/.git ]; then git clone https://github.com/creationix/nvm.git $(NVM_DIR); fi
	. $(NVM_DIR)/nvm.sh; nvm install --lts

rvm:
	if ! [ -d $(RVM_DIR)/bin ]; then curl -sSL https://get.rvm.io | bash -s stable --ruby; fi

brew-packages: brew clean-python
	brew bundle --file=$(DOTFILES_DIR)/macos/install/Brewfile

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/macos/install/Caskfile || true
	xattr -d -r com.apple.quarantine ~/Library/QuickLook

tmux: brew
	brew install tmux;
	if ! [ -d $(TMUX_DIR)/.git ]; then git clone https://github.com/gpakosz/.tmux.git $(TMUX_DIR); fi
	ln -s -f $(TMUX_DIR)/.tmux.conf $(HOME)/.tmux.conf;

test:
	. $(NVM_DIR)/nvm.sh; bats test

clean-python:
	rm -f '/usr/local/bin/2to3'

keylayout:
	mkdir -p ~/Library/Keyboard\ Layouts && \
	cd ~/Library/Keyboard\ Layouts && \
	curl https://qwerty-lafayette.org/releases/lafayette_macosx_v0.6.keylayout --output lafayette_macosx.keylayout

java: brew
	brew tap adoptopenjdk/openjdk;
	brew install --cask adoptopenjdk/openjdk/adoptopenjdk8 adoptopenjdk11 adoptopenjdk15;
	brew install maven gradle;
	if ! [ -d $(JENV_DIR)/.git ]; then git clone https://github.com/jenv/jenv.git $(JENV_DIR); fi
	mkdir -p $(JENV_DIR)/versions;
	jenv add /Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home;
	jenv add /Library/Java/JavaVirtualMachines/adoptopenjdk-11.jdk/Contents/Home;
	jenv add /Library/Java/JavaVirtualMachines/adoptopenjdk-15.jdk/Contents/Home;
	jenv global 11;
