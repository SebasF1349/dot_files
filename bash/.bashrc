# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ -f ~/.welcome_screen ]] && . ~/.welcome_screen

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=erasedups:ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

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
    xterm-color|*-256color) color_prompt=yes;;
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
    . ~/.bash_aliases
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
fi

[[ -z "$FUNCNEST" ]] && export FUNCNEST=100          # limits recursive functions, see 'man bash'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# use arrows to move in history with the same first letters
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
# trick: use `cat > /dev/null` to see the input of your keys

alias eza='eza -lah'
alias ezat="eza --tree --level=2"

##fzf
# Use ~~ as the trigger sequence instead of the default **
export FZF_COMPLETION_TRIGGER='ºº'
# Options to fzf command
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

if [[ $iatest > 0 ]]; then bind "set completion-ignore-case on"; fi

eval "$(starship init bash)"

# pnpm
export PNPM_HOME="/home/sebasf/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
. "$HOME/.cargo/env"

export PATH="/home/sebasf/.local/share/bob/nvim-bin/:$PATH"
export EDITOR=nvim

alias cd..="cd .."
alias ..="cd .."
alias ...="cd ../.."

alias g="git"
alias gstatus="git status"
alias gdiff="git diff"
alias gcommit="git commit -m"
alias gclone="git clone"
alias gadd="git add ."
alias gaddall="git add --all"
alias gbranch="git branch"
alias gcheckout="git checkout"
alias gpush="git push"
alias gpull="git pull"

alias nv="${EDITOR}"
alias nv.="${EDITOR} ."
alias bashrc="${EDITOR} ~/.bashrc"
alias snv="sudo ${EDITOR}"

cl() {
    local dir="$1"
    local dir="${dir:=$HOME}"
    if [[ -d "$dir" ]]; then
	    cd "$dir" >/dev/null; eza -lah
    else
	    echo "bash: cl: $dir: Directory not found"
    fi
}

shopt -s autocd

mkcd() {
    mkdir -p -- "$1" &&
	cd -P -- "$1"
}

# do sudo, or sudo the last command if no argument given
s() { 
    if [[ $# == 0 ]]; then
        sudo $(history -p '!!')
    else
        sudo "$@"
    fi
}

extract () {
     if [ -f $1 ] ; then
         case $1 in
             *.tar.bz2)   tar xjf $1        ;;
             *.tar.gz)    tar xzf $1     ;;
             *.bz2)       bunzip2 $1       ;;
             *.rar)       rar x $1     ;;
             *.gz)        gunzip $1     ;;
             *.tar)       tar xf $1        ;;
             *.tbz2)      tar xjf $1      ;;
             *.tgz)       tar xzf $1       ;;
             *.zip)       unzip $1     ;;
             *.Z)         uncompress $1  ;;
             *.7z)        7z x $1    ;;
             *)           echo "'$1' cannot be extracted via extract()" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}

#Copy and go to dir
cpg (){
    if [ -d "$2" ];then
        cp $1 $2 && cd $2
    else
        cp $1 $2
    fi
}

#Move and go to dir
mvg (){
    if [ -d "$2" ];then
        mv $1 $2 && cd $2
    else
        mv $1 $2
    fi
}


if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    DISTRO=$ID_LIKE
fi

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

    export FLYCTL_INSTALL="/home/sebasf/.fly"
    export PATH="$FLYCTL_INSTALL/bin:$PATH"

    # If this is an xterm set the title to user@host:dir
    case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
    esac

    alias proyectos="cd ~/Proyectos"
    alias dot="cd ~/Proyectos/dot_files"

elif [ "$DISTRO" = "arch" ]; then
    _set_liveuser_PS1() {
        PS1='[\u@\h \W]\$ '
        if [ "$(whoami)" = "liveuser" ] ; then
            local iso_version="$(grep ^VERSION= /usr/lib/endeavouros-release 2>/dev/null | cut -d '=' -f 2)"
            if [ -n "$iso_version" ] ; then
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
        if [ -r $file ] ; then
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

        if [ -x /usr/bin/exo-open ] ; then
            echo "exo-open $@" >&2
            setsid exo-open "$@" >& /dev/null
            return
        fi
        if [ -x /usr/bin/xdg-open ] ; then
            for file in "$@" ; do
                echo "xdg-open $file" >&2
                setsid xdg-open "$file" >& /dev/null
            done
            return
        fi

        echo "$FUNCNAME: package 'xdg-utils' or 'exo' is required." >&2
    }

    alias tup="cd ~/tup"
    alias dot="cd ~/dot_files"
    alias repos="cd ~/repos"

    # pacman + fzf
    # install
    alias fuzi="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
    # remove
    alias fuzr="pacman -Qq | fzf --multi --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns"
    # install with yay?
    alias yayi="yay -Slq | fzf --multi --preview 'yay -Si {1}' | xargs -ro yay -S"
fi

# WELCOME WINDOW
LIGHTGREEN="\e[1;32m"
clear
echo -ne "${LIGHTGREEN}"; date
curl wttr.in/Bahia+Blanca?format="Temp:%t%20-%20Feels:%f\n"
echo ""
