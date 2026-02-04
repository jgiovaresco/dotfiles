if [[ -z "$PROFILE_SOURCED" ]]; then
    source ~/.zprofile
fi

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Uncomment to change how often before auto-updates occur? (in days)
export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

bindkey -e
bindkey '^[[1;9C' forward-word
bindkey '^[[1;9D' backward-word

# Remove user@host prefix
export DEFAULT_USER="jgiovaresco"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
plugins=(autojump direnv zsh-syntax-highlighting zsh-autosuggestions git macos brew docker docker-compose sudo extract gradle npm kubectl helm mvn)

autoload -U compinit && compinit
autoload -U bashcompinit && bashcompinit
if [ $commands[flux] ]; then
  source <(flux completion zsh)
fi

source $ZSH/oh-my-zsh.sh

# Resolve DOTFILES_DIR (assuming ~/.dotfiles on distros without readlink and/or $BASH_SOURCE/$0)

READLINK=$(which greadlink 2>/dev/null || which readlink)
CURRENT_SCRIPT=$HOME/.zshrc

if [[ -n $CURRENT_SCRIPT && -x "$READLINK" ]]; then
  SCRIPT_PATH=$($READLINK -f "$CURRENT_SCRIPT")
  DOTFILES_DIR=$(dirname "$(dirname "$SCRIPT_PATH")")
elif [ -d "$HOME/.dotfiles" ]; then
  DOTFILES_DIR="$HOME/.dotfiles"
else
  echo "Unable to find dotfiles, exiting."
  return
fi

# Make utilities available

PATH="$DOTFILES_DIR/bin:$PATH"

# Source the dotfiles (order matters)

for DOTFILE in "$DOTFILES_DIR"/system/.{function,path,env,alias,starship,nvm,rust,gpg,custom}; do
  [ -f "$DOTFILE" ] && . "$DOTFILE"
done

if is-macos; then
  for DOTFILE in "$DOTFILES_DIR"/system/.{env,alias,function,path}.macos; do
    [ -f "$DOTFILE" ] && . "$DOTFILE"
  done
fi

# Clean up

unset READLINK CURRENT_SCRIPT SCRIPT_PATH DOTFILE

# Export

export DOTFILES_DIR DOTFILES_EXTRA_DIR

# Direnv
eval "$(direnv hook zsh)"

if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/jgiovaresco/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
