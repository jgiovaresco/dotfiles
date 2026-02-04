SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos)
PATH := $(DOTFILES_DIR)/bin:$(PATH)
NVM_DIR := $(HOME)/.nvm
RVM_DIR := $(HOME)/.rvm
OMZSH_DIR := $(HOME)/.oh-my-zsh
ZSH_CUSTOM := $(OMZSH_DIR)/custom
TMUX_DIR := $(HOME)/.tmux

SDKMAN_DIR := $(HOME)/.sdkman

export XDG_CONFIG_HOME := $(HOME)/.config
export STOW_DIR := $(DOTFILES_DIR)

.PHONY: test

all: $(OS)

macos: sudo core-macos keylayout packages link

core-macos: brew zsh oh-my-zsh git npm tmux

stow-macos: brew
	is-executable stow || brew install stow

sudo:
ifndef GITHUB_ACTION
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

packages: brew-packages cask-apps

link: stow-$(OS)
	mkdir -p $(XDG_CONFIG_HOME)
	stow -t $(XDG_CONFIG_HOME) config
	ln -sf $(DOTFILES_DIR)/myshell/.zshrc $(HOME)/.zshrc
	ln -sf $(DOTFILES_DIR)/myshell/.zprofile $(HOME)/.zprofile
	ln -sf $(DOTFILES_DIR)/myshell/.tmux.conf $(HOME)/.tmux.conf.local


unlink:
	stow --delete -t $(XDG_CONFIG_HOME) config
	rm $(HOME)/.zshrc
	rm $(HOME)/.zprofile
	rm $(HOME)/.tmux.conf.local

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash
	grep -q 'brew shellenv' /Users/$(USER)/.zprofile || echo 'eval "$$(/opt/homebrew/bin/brew shellenv)"' >> /Users/$(USER)/.zprofile
	eval "$$(/opt/homebrew/bin/brew shellenv)"

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
	if ! [ -d $(SDKMAN_DIR) ]; then curl -s "https://get.sdkman.io" | bash; fi
	ln -sf ${DOTFILES_DIR}/config/sdkman/config ${SDKMAN_DIR}/etc/config;

	if ! [ -d $(SDKMAN_DIR)/candidates/java/17.0.13-tem ]; then . ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk install java 17.0.13-tem; fi
	if ! [ -d $(SDKMAN_DIR)/candidates/java/21.0.6-tem ]; then . ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk install java 21.0.6-tem; fi
	if ! [ -d $(SDKMAN_DIR)/candidates/maven ]; then . ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk install maven; fi
	if ! [ -d $(SDKMAN_DIR)/candidates/gradle ]; then . ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk install gradle; fi

	. ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk default java 21.0.6-tem;
