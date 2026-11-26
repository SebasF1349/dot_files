# shellcheck disable=SC1090,SC1091
[[ $- != *i* ]] && return

[[ -z $DISPLAY && $(tty) == /dev/tty1 ]] && command -v startx >/dev/null && exec startx

shopt -s histappend checkwinsize autocd extglob cmdhist cdspell nocaseglob histverify
set -o ignoreeof # ctrl-d on an empty line doesn't exit the shell, use `exit`
# ignorespace is stripped by bash-preexec (OSC133.sh), so use HISTIGNORE for that instead
HISTCONTROL=erasedups
HISTIGNORE=' *'
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT='%F %T '
# on every prompt, save new commands to the history file and load the ones other terminals saved
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
FUNCNEST=100

export EDITOR=nvim
export MANPAGER='nvim +Man!'
export GIT_BASE=main
export CHROME_EXECUTABLE=/usr/bin/chromium
export ELECTRON_OZONE_PLATFORM_HINT=auto
export ANDROID_HOME=$HOME/Android/Sdk
export PNPM_HOME="$HOME/.local/share/pnpm"
export FLYCTL_INSTALL="$HOME/.fly"
export NVM_DIR="$HOME/.nvm"
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border --bind ctrl-j:preview-half-page-down,ctrl-k:preview-half-page-up'
export FZF_COMPLETION_OPTS='--border --info=inline'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'head -n 500 {}'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# prepends each existing dir to PATH, in order (the last one ends up first)
path_add() {
    local d
    for d; do [[ ":$PATH:" != *":$d:"* && -d $d ]] && PATH="$d:$PATH"; done
}

# nvm is slow to source: put the default node on PATH now (the newest one if the
# default alias isn't a version number) and only load nvm on the first `nvm` call
if [ -s "$NVM_DIR/nvm.sh" ]; then
    { read -r _v <"$NVM_DIR/alias/default"; } 2>/dev/null
    [[ $_v =~ ^v?([0-9].*) ]] && _v=${BASH_REMATCH[1]} || _v=
    _node=$(printf '%s\n' "$NVM_DIR"/versions/node/v"$_v"*/bin | sort -V | tail -n1)
    nvm() {
        unset -f nvm
        . "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        nvm "$@"
    }
fi
path_add ~/scripts ~/.local/bin "$ANDROID_HOME/platform-tools" /opt/gradle-8.9/bin \
    "$ANDROID_HOME/cmdline-tools/latest/bin" "$PNPM_HOME" ~/.config/composer/vendor/bin \
    "$_node" "$FLYCTL_INSTALL/bin" ~/.cargo/bin /usr/local/go/bin
unset _v _node

if ! shopt -oq posix; then
    for f in /usr/share/bash-completion/bash_completion /usr/share/bash-completion/completions/git; do
        [ -f "$f" ] && . "$f"
    done
    unset f
fi

command -v fzf >/dev/null && eval "$(fzf --bash)"
_fzf_compgen_path() { fd --hidden --follow --exclude ".git" . "$1"; }
_fzf_compgen_dir() { fd --type d --hidden --follow --exclude ".git" . "$1"; }

[[ $TERM != linux && -f ~/dot_files/bash/OSC133.sh ]] && . ~/dot_files/bash/OSC133.sh

# arrows search history for commands starting with the typed text
# (\e[A is normal cursor mode, \eOA is application cursor mode)
bind '"\e[A": history-search-backward' '"\eOA": history-search-backward'
bind '"\e[B": history-search-forward' '"\eOB": history-search-forward'

[ -f ~/.bash_aliases ] && . ~/.bash_aliases

alias tup="cd ~/tup"
alias dot="cd ~/dot_files"
alias repos="cd ~/repos"
alias ..="cd .."
alias ...="cd ../.."
alias cp="cp -iv"
alias df='df -h'
alias free='free -m'
alias du='du -hc'
alias psgrep="pgrep -af"
alias grep='grep --color=auto'
alias nocomment="grep -Ev '^[[:space:]]*(#|$)'"
command -v tree >/dev/null || alias tree="find . -not -path './.git*' -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
ll() { command ls -lAhFv --color=always --time-style=long-iso "$@" | less -R -X -F; }
mkcd() { mkdir -p -- "$1" && cd -P -- "$1" || return; }

extract() {
    [[ -f "$1" ]] || {
        echo "'$1' is not a valid file" >&2
        return 1
    }
    case "$1" in
    # tar detects the compression itself
    *.tar | *.tar.* | *.tgz | *.tbz2 | *.txz | *.tzst) tar xf "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.gz) gunzip "$1" ;;
    *.xz) unxz "$1" ;;
    *.zst) unzstd "$1" ;;
    *.rar) rar x "$1" ;;
    *.zip) unzip "$1" ;;
    *.7z) 7z x "$1" ;;
    *)
        echo "'$1' cannot be extracted via extract()" >&2
        return 1
        ;;
    esac
}

alias nv='${EDITOR}'
alias nvbash='${EDITOR} ~/.bashrc && source ~/.bashrc'
alias sourcebash='source ~/.bashrc'
alias snv='sudo ${EDITOR}'

# gd ideas from https://blog.jez.io/cli-code-review/
current_branch() { git symbolic-ref --short -q HEAD; }
git_diff_branch() { git diff --stat "$(git merge-base HEAD "${1:-$GIT_BASE}")"; }

git_checkout_fzf() {
    local branch
    # origin/HEAD shows up as plain "origin", so drop it
    branch=$(git branch --all --sort=-committerdate --format='%(refname:short)' |
        grep -vx 'origin' |
        fzf --height "90%" --header "CHECKOUT BRANCH" --preview "git diff --color=always {1}" --pointer=">" |
        sed "s#^origin/##")
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
alias gdlc="git diff --cached HEAD^" #show diff of last commit + staged changes
alias gc="git commit -m"
alias gac="git commit -am"
alias gca="git commit -a --amend --no-edit"
alias gcl="git clone"
alias ga="git add"
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
alias gll="gl --numstat"

# tab completion for the git aliases (alias:git-subcommand)
if declare -F __git_complete >/dev/null; then
    __git_complete g __git_main
    for a in gd:diff ga:add gb:branch gbd:branch gch:checkout gcb:checkout gP:push gp:pull gst:stash gl:log gll:log; do
        __git_complete "${a%%:*}" "_git_${a#*:}"
    done
    unset a
fi

case $(
    . /etc/os-release 2>/dev/null
    echo "${ID_LIKE:-$ID}"
) in
*debian*)
    alias up="sudo apt update && sudo apt upgrade && flatpak update"
    alias clean="sudo apt autoclean && sudo apt autoremove"
    ;;
*arch*)
    # fuzzy install (i) / remove (r) packages with pacman (fuz*) or yay (yay*)
    alias fuzi="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
    alias fuzr="pacman -Qq | fzf --multi --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns"
    alias yayi="yay -Slq | fzf --multi --preview 'yay -Si {1}' | xargs -ro yay -S"
    alias yayr="yay -Qq | fzf --multi --preview 'yay -Qi {1}' | xargs -ro yay -Rns"
    ;;
esac

[ -f ~/.bashrc_local ] && . ~/.bashrc_local

if [[ $TERM != linux ]] && command -v starship >/dev/null; then
    eval "$(starship init bash)"
else
    PS1='\u@\h:\w\$ '
fi
