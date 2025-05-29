# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=erasedups:ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# vi mode
set -o vi

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=500
HISTFILESIZE=500

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    DISTRO=$ID_LIKE
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    # shellcheck disable=SC1091
    source "$HOME"/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
    . /usr/share/bash-completion/completions/git
fi

[[ -z "$FUNCNEST" ]] && export FUNCNEST=100 # limits recursive functions, see 'man bash'

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# shellcheck disable=SC1091
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# use arrows to move in history with the same first letters
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
# trick: use `cat > /dev/null` to see the input of your keys

alias eza='eza -lah'
alias ezat="eza --tree --level=2"

##fzf
if [ "$DISTRO" = "debian" ]; then
    export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'
elif [ "$DISTRO" = "arch" ]; then
    export FZF_DEFAULT_OPTS='--height ~50% --layout=reverse --border'

    wifi_info=$(ip -4 -o addr show wlan0)
    if [ -z "$wifi_info" ]; then
        nmcli radio wifi off &
        sleep 1 &
        nmcli radio wifi on
    fi
fi
# Options to fzf command
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_COMPLETION_OPTS='--border --info=inline'
# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
    fd --hidden --follow --exclude ".git" . "$1"
}
# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude ".git" . "$1"
}

export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export CHROME_EXECUTABLE=/usr/bin/chromium

# if [[ $iatest > 0 ]]; then bind "set completion-ignore-case on"; fi

eval "$(starship init bash)"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

if [ -d ~/.cargo ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
    if [ -f ~/.cargo/env ]; then
        # shellcheck disable=SC1091
        source "$HOME/.cargo/env"
    fi
fi

export ELECTRON_OZONE_PLATFORM_HINT=auto
export EDITOR=nvim
export MANPAGER='nvim +Man!'

alias cd..="cd .."
alias ..="cd .."
alias ...="cd ../.."

# git

export GIT_BASE=main

function current_branch() {
    branch_name=$(git symbolic-ref --short -q HEAD)
    echo "$branch_name"
}

# gd ideas from https://blog.jez.io/cli-code-review/
function git_diff_branch() {
    local review_base="${1:-$GIT_BASE}"
    git diff --stat "$(git merge-base HEAD "$review_base")"
}

function git_checkout_fzf() {
    branch=$(git branch --sort=-committerdate --all |
        fzf --height "90%" --header "PLEASE CHOOSE A BRANCH TO CHECKOUT" --preview "git diff --color=always {1}" --pointer=">" |
        sed "s/remotes\/origin\///" | xargs)
    if [ -n "$branch" ]; then
        git checkout "$branch"
    fi
}

alias g="git"
alias gs="git status"
alias gd="git diff"
alias gdf='git diff --name-only ..origin/$(current_branch)'
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
alias gpush="git push"
alias gf='git fetch && git diff --name-only ..origin/$(current_branch)'
alias gp="git pull"
alias gpull="git pull"
alias gst="git stash"
alias gu="git reset HEAD~1 --mixed"
alias gl="git log --graph --pretty=format:\"%C(yellow)%h %Cred%d %Creset%s%Cblue [%cn - %ar]\" --decorate"
alias gll="git log --graph --pretty=format:\"%C(yellow)%h %Cred%d %Creset%s%Cblue [%cn - %ar]\" --decorate --numstat" #with files changed

alias nv='${EDITOR}'
alias nv.='${EDITOR} .'
alias nvbash='${EDITOR} ~/.bashrc && source ~/.bashrc'
alias sourcebash='source ~/.bashrc'
alias snv='sudo ${EDITOR}'

nvf() {
    local dir="${1:-.}"
    if [[ "$dir" == "repos" ]]; then
        dir="${HOME}/repos/"
    elif [[ "$dir" == "dot" ]]; then
        dir="${HOME}/dot_files/"
    fi
    selected_dir=$(fd . "${dir}" --type d --max-depth 2 | fzf)
    if [[ -n "$selected_dir" ]]; then
        cd "$selected_dir" || exit #&& ${EDITOR} .
        files=("$(fzf --multi --select-1 --exit-0 --preview "bat --color=always --style=numbers --line-range=:500 {}")")
        [[ -n "${files[*]}" ]] && ${EDITOR:-vim} "${files[@]}"
    fi
}

#   - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
nvff() {
    IFS=$'\n' files=("$(fzf --query="$1" --multi --select-1 --exit-0 --preview "bat --color=always --style=numbers --line-range=:500 {}")")
    [[ -n "${files[*]}" ]] && ${EDITOR:-vim} "${files[@]}"
}

alias tup="cd ~/tup"
alias dot="cd ~/dot_files"
alias repos="cd ~/repos"

cdf() {
    local dir
    dir=$(fd . "${1:-$HOME}" --type d | fzf +m)
    if [[ -n "$dir" ]]; then
        cd "$dir" || exit
    fi
}

cl() {
    local dir="${1:=$HOME}"
    if [[ -d "$dir" ]]; then
        cd "$dir" >/dev/null || exit
        eza -lah
    else
        echo "bash: cl: $dir: Directory not found"
    fi
}

shopt -s autocd

mkcd() {
    mkdir -p -- "$1" &&
        cd -P -- "$1" || exit
}

# cd if dir or edit if file
t() {
    if [[ $# -eq 1 && (-d "$1" || "$1" == "-") ]]; then
        builtin cd "$1" || return
        if command -v eza >/dev/null 2>&1; then
            eza -lah
        else
            ls -bvxAF --color --group-directories-first
        fi
    elif test $# -eq 0; then
        builtin cd "$HOME" || return
    elif test -f "$1" || test ! -e "$1" || test $# -gt 1; then
        $EDITOR "$@"
    else
        printf "t: case not accounted for\n"
    fi
}

# do sudo, or sudo the last command if no argument given
s() {
    if [[ $# == 0 ]]; then
        sudo "$(history -p '!!')"
    else
        sudo "$@"
    fi
}

extract() {
    if [ -f "$1" ]; then
        case $1 in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz) tar xzf "$1" ;;
        *.bz2) bunzip2 "$1" ;;
        *.rar) rar x "$1" ;;
        *.gz) gunzip "$1" ;;
        *.tar) tar xf "$1" ;;
        *.tbz2) tar xjf "$1" ;;
        *.tgz) tar xzf "$1" ;;
        *.zip) unzip "$1" ;;
        *.Z) uncompress "$1" ;;
        *.7z) 7z x "$1" ;;
        *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

#Copy and go to dir
cpg() {
    if [ -d "$2" ]; then
        cp "$1" "$2" && cd "$2" || exit
    else
        cp "$1" "$2"
    fi
}

#Move and go to dir
mvg() {
    if [ -d "$2" ]; then
        mv "$1" "$2" && cd "$2" || exit
    else
        mv "$1" "$2"
    fi
}

#Install scripts
export PATH=$PATH:~/dot_files/install_scripts/
export PATH=$PATH:/usr/local/go/bin

if [ "$DISTRO" = "debian" ]; then
    # set variable identifying the chroot you work in (used in the prompt below)
    if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
        debian_chroot=$(cat /etc/debian_chroot)
    fi

    if [ "$color_prompt" = yes ]; then
        #PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]sebas\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    fi
    unset color_prompt force_color_prompt

    alias uu="sudo apt update && sudo apt upgrade"
    alias clean="sudo apt autoclean && sudo apt autoremove"

    export FLYCTL_INSTALL="$HOME/.fly"
    export PATH="$FLYCTL_INSTALL/bin:$PATH"

    # If this is an xterm set the title to user@host:dir
    case "$TERM" in
    xterm* | rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *) ;;
    esac
elif [ "$DISTRO" = "arch" ]; then
    _set_liveuser_PS1() {
        PS1='[\u@\h \W]\$ '
        if [ "$(whoami)" = "liveuser" ]; then
            local iso_version
            iso_version="$(grep ^VERSION= /usr/lib/endeavouros-release 2>/dev/null | cut -d '=' -f 2)"
            if [ -n "$iso_version" ]; then
                local prefix="eos-"
                local iso_info="$prefix$iso_version"
                PS1="[\u@$iso_info \W]\$ "
            fi
        fi
    }
    _set_liveuser_PS1
    unset -f _set_liveuser_PS1

    ShowInstallerIsoInfo() {
        local file=/usr/lib/endeavouros-release
        if [ -r $file ]; then
            cat $file
        else
            echo "Sorry, installer ISO info is not available." >&2
        fi
    }

    [[ "$(whoami)" = "root" ]] && return

    _open_files_for_editing() {
        # Open any given document file(s) for editing (or just viewing).
        # Note1:
        #    - Do not use for executable files!
        # Note2:
        #    - Uses 'mime' bindings, so you may need to use
        #      e.g. a file manager to make proper file bindings.

        if [ -x /usr/bin/exo-open ]; then
            echo "exo-open $*" >&2
            setsid exo-open "$@" >&/dev/null
            return
        fi
        if [ -x /usr/bin/xdg-open ]; then
            for file in "$@"; do
                echo "xdg-open $file" >&2
                setsid xdg-open "$file" >&/dev/null
            done
            return
        fi

        echo "${FUNCNAME[*]}: package 'xdg-utils' or 'exo' is required." >&2
    }

    # pacman + fzf
    # install
    alias fuzi="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
    # remove
    alias fuzr="pacman -Qq | fzf --multi --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns"
    # install with yay
    alias yayi="yay -Slq | fzf --multi --preview 'yay -Si {1}' | xargs -ro yay -S"
    # remove with yay
    alias yayr="yay -Qq | fzf --multi --preview 'yay -Qi {1}' | xargs -ro yay -Rns"
fi

# WELCOME WINDOW
clear
#LIGHTGREEN="\e[1;32m"
#echo -ne "${LIGHTGREEN}"; date
#curl wttr.in/Bahia+Blanca?format="Temp:%t%20-%20Feels:%f\n"
#echo ""
