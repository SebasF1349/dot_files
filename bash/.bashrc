# ~/.bashrc: executed by bash(1) for non-login shells.
# shellcheck disable=SC1091

# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# 1. EARLY EXIT & SHELL OPTIONS
[[ $- != *i* ]] && return

set -o vi
shopt -s histappend checkwinsize autocd extglob cmdhist cdspell nocaseglob histverify
HISTCONTROL=erasedups:ignoredups:ignorespace
HISTSIZE=10000
HISTFILESIZE=10000

# 2. HELPERS
path_add() {
    if [[ ":$PATH:" != *":$1:"* ]] && [ -d "$1" ]; then
        export PATH="$1:$PATH"
    fi
}

# 3. ENVIRONMENT & TOOLS
export EDITOR=nvim
export MANPAGER='nvim +Man!'
export FUNCNEST=100
export CHROME_EXECUTABLE=/usr/bin/chromium
export ELECTRON_OZONE_PLATFORM_HINT=auto

path_add ~/dot_files/install_scripts/
path_add ~/scripts/

# 4. THIRD PARTY TOOLS
export ANDROID_HOME=$HOME/android-sdk
path_add "$ANDROID_HOME/platform-tools"

export PNPM_HOME="$HOME/.local/share/pnpm"
path_add "$PNPM_HOME"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export FLYCTL_INSTALL="$HOME/.fly"
path_add "$FLYCTL_INSTALL/bin"

path_add "$HOME/.cargo/bin"

path_add /usr/local/go/bin

export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'
export FZF_COMPLETION_OPTS='--border --info=inline'
_fzf_compgen_path() { fd --hidden --follow --exclude ".git" . "$1"; }
_fzf_compgen_dir() { fd --type d --hidden --follow --exclude ".git" . "$1"; }

# 5. SOURCING
[ -f /etc/os-release ] && . /etc/os-release
[ -f ~/.bash_aliases ] && . "$HOME/.bash_aliases"
[ -f "$HOME/dot_files/bash/OSC133.sh" ] && . "$HOME/dot_files/bash/OSC133.sh"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
    [ -f /usr/share/bash-completion/completions/git ] && . /usr/share/bash-completion/completions/git
fi

# 6. INTERACTIVE & ALIASES
# use arrows to move in history with the same first letters
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
# trick: use `cat > /dev/null` to see the input of your keys
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

alias tup="cd ~/tup"
alias dot="cd ~/dot_files"
alias repos="cd ~/repos"

alias eza='eza -lah'
alias ezat="eza --tree --level=2"
alias ..="cd .."
alias ...="cd ../.."
alias cp="cp -iv"
alias df='df -h'
alias free='free -m'
alias du='du -hc'
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"

alias nocomment="grep -Ev '^[[:space:]]*(#|$)'"
alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"

function ll {
    command ls -lAhFv --color=always --time-style=long-iso "$@" | less -R -X -F
}

if [ -x /usr/bin/dircolors ]; then
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# 7. GIT INTEGRATION
export GIT_BASE=main

# gd ideas from https://blog.jez.io/cli-code-review/
current_branch() { git symbolic-ref --short -q HEAD; }
git_diff_branch() { git diff --stat "$(git merge-base HEAD "${1:-$GIT_BASE}")"; }

git_checkout_fzf() {
    local branch
    branch=$(git branch --sort=-committerdate --all |
        fzf --height "90%" --header "CHECKOUT BRANCH" --preview "git diff --color=always {1}" --pointer=">" |
        sed "s/remotes\/origin\///" | xargs)
    [[ -n "$branch" ]] && git checkout "$branch"
}

alias g="git"
alias gs="git status"
alias gd="git diff"
alias gdf='git diff --name-only @{u}'
alias gdn='git diff --name-only $(git merge-base HEAD "$GIT_BASE")'
alias gdv='nvim -p $(gdn) +"tabdo Gdiffsplit $(current_branch)"'
alias gdvf='nvim -p +"tabdo Gdiffsplit $(current_branch)"'
alias gdb='git_diff_branch'
alias gdlc="git diff --cached HEAD^" #show diff of last commit
alias gc="git commit -m"
alias gac="git commit -am"
alias gca="commit -a --amend --no-edit"
alias gcl="git clone"
alias ga="git add"
alias ga.="git add ."
alias gad="git add ."
alias gaa="git add --all"
alias gap="git add --patch"
alias gb="git branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate"
alias gbd="git branch -D"
alias gch="git checkout"
alias gcb="git checkout -b"
alias gcf="git_checkout_fzf"
alias gP="git push"
alias gf='git fetch && git diff --name-only @{u}'
alias gp="git pull"
alias gst="git stash"
alias gu="git reset HEAD~1 --mixed"
alias gl="git log --graph --pretty=format:\"%C(yellow)%h %Cred%d %Creset%s%Cblue [%cn - %ar]\" --decorate"
alias gll="git log --graph --pretty=format:\"%C(yellow)%h %Cred%d %Creset%s%Cblue [%cn - %ar]\" --decorate --numstat" #with files changed

# 8. WORKFLOW FUNCTIONS
alias nv='${EDITOR}'
alias nvbash='${EDITOR} ~/.bashrc && source ~/.bashrc'
alias sourcebash='source ~/.bashrc'
alias snv='sudo ${EDITOR}'

nvf() {
    local dir="${1:-.}"
    [[ "$dir" == "repos" ]] && dir="${HOME}/repos/"
    [[ "$dir" == "dot" ]] && dir="${HOME}/dot_files/"

    local selected_dir
    selected_dir=$(fd . "${dir}" --type d --max-depth 2 | fzf)
    if [[ -n "$selected_dir" ]]; then
        cd "$selected_dir" || return
        local files
        IFS=$'\n' files=("$(fzf --multi --select-1 --exit-0 --preview "bat --color=always --style=numbers --line-range=:500 {}")")
        [[ -n "${files[*]}" ]] && ${EDITOR:-vim} "${files[@]}"
    fi
}

nvff() {
    local files
    IFS=$'\n' files=("$(fzf --query="$1" --multi --select-1 --exit-0 --preview "bat --color=always --style=numbers --line-range=:500 {}")")
    [[ -n "${files[*]}" ]] && ${EDITOR:-vim} "${files[@]}"
}

cdf() {
    local dir
    dir=$(fd . "${1:-$HOME}" --type d | fzf +m)
    [[ -n "$dir" ]] && cd "$dir" || exit
}

cl() {
    local dir="${1:=$HOME}"
    if [[ -d "$dir" ]]; then
        cd "$dir" >/dev/null && eza -lah
    else
        echo "bash: cl: $dir: Directory not found" >&2
    fi
}

mkcd() { mkdir -p -- "$1" && cd -P -- "$1" || exit; }

extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
        *.tar.bz2 | *.tbz2) tar xjf "$1" ;;
        *.tar.gz | *.tgz) tar xzf "$1" ;;
        *.bz2) bunzip2 "$1" ;;
        *.rar) rar x "$1" ;;
        *.gz) gunzip "$1" ;;
        *.tar) tar xf "$1" ;;
        *.zip) unzip "$1" ;;
        *.7z) 7z x "$1" ;;
        *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file" >&2
    fi
}

if [ -f /etc/os-release ]; then
    . /etc/os-release
    case ${ID_LIKE:-$ID} in
    debian)
        [ -r /etc/debian_chroot ] && debian_chroot=$(cat /etc/debian_chroot)
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]sebas\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
        alias uu="sudo apt update && sudo apt upgrade"
        alias clean="sudo apt autoclean && sudo apt autoremove"
        ;;
    arch)
        # wifi_info=$(ip -4 -o addr show wlan0)
        # if [ -z "$wifi_info" ]; then
        #     nmcli radio wifi off &
        #     sleep 1 &
        #     nmcli radio wifi on
        # fi

        # pacman + fzf
        # install
        alias fuzi="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
        # remove
        alias fuzr="pacman -Qq | fzf --multi --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns"
        # install with yay
        alias yayi="yay -Slq | fzf --multi --preview 'yay -Si {1}' | xargs -ro yay -S"
        # remove with yay
        alias yayr="yay -Qq | fzf --multi --preview 'yay -Qi {1}' | xargs -ro yay -Rns"
        ;;
    esac
fi

eval "$(starship init bash)"
