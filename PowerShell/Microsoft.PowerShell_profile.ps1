# Create profile
# New-Item -Type file -Path $PROFILE -Force

# Open
# notepad $PROFILE

$dot_files = Write-Output (Get-Item $PROFILE).ResolveLinkTarget('true').Directory.Parent.FullName
Import-Module $dot_files\install_scripts\install-neovim.ps1

# Utils

function uu {
    winget update
}

# Dirs

function .. {
    Set-Location ..
}

function cdf {
    param (
        [string]$dir = $env:HOME
    )

    $selected_dir = fd $dir --type d | fzf +m

    if ($selected_dir) {
        Set-Location -Path $selected_dir
    }
}


function eza {
    $exe = (Get-Command eza -CommandType Application).Source
    Start-Process $exe -ArgumentList "-lah" -NoNewWindow
}

# Nvim

$env:EDITOR = 'nvim'

Remove-Item -Force Alias:nv
Set-Alias nv nvim

function nvf {
    param (
        [string]$dir = "."
    )

    $selected_dir = fd $dir --type d --max-depth 2 | fzf

    if ($selected_dir) {
        Set-Location -Path $selected_dir

        $files = fzf --multi --select-1 --exit-0 --preview "bat --color=always --style=numbers --line-range=:500 {}" | Out-String
        $files = $files.Trim()

        if ($files) {
            $editor = $env:EDITOR
            if (-not $editor) {
                $editor = "vim"
            }
            & $editor $files
        }
    }
}

function nvff {
    param([string]$query)

    $files = fzf --query="$query" --multi --select-1 --exit-0 --preview "bat --color=always --style=numbers --line-range=:500 {}" | Out-String
    $files = $files.Trim()

    if ($files) {
        $editor = $env:EDITOR
        if (-not $editor) {
            $editor = "vim"
        }
        & $editor $files
    }
}

# Git

$env:GIT_BASE = 'main'

# Based on https://github.com/gluons/powershell-git-aliases/blob/master/src/aliases.ps1

function Get-Git-CurrentBranch {
	git symbolic-ref --quiet HEAD *> $null

	if ($LASTEXITCODE -eq 0) {
		return git rev-parse --abbrev-ref HEAD
	} else {
		return
	}
}

# Prevent conflict with built-in aliases
Remove-Alias gc -Force -ErrorAction SilentlyContinue
Remove-Alias gcb -Force -ErrorAction SilentlyContinue
Remove-Alias gcm -Force -ErrorAction SilentlyContinue
Remove-Alias gcs -Force -ErrorAction SilentlyContinue
Remove-Alias gl -Force -ErrorAction SilentlyContinue
Remove-Alias gm -Force -ErrorAction SilentlyContinue
Remove-Alias gp -Force -ErrorAction SilentlyContinue
Remove-Alias gpv -Force -ErrorAction SilentlyContinue

function g {
	git $args
}
function ga {
	git add $args
}
function gaa {
	git add --all $args
}
function gad {
	git add . $args
}
function gap {
	git add --patch $args
}
function gs {
	git status $args
}
function gd {
	git diff $args
}
function gdf {
	$CurrentBranch = Get-Git-CurrentBranch

	git diff --name-only ..origin/$CurrentBranch $args
}
function gdn {
    git diff --name-only $(git merge-base HEAD $env:GIT_BASE)
}
function gdv {
	$CurrentBranch = Get-Git-CurrentBranch

    nvim -p $(gdn) +"tabdo Gdiffsplit $CurrentBranch"
}
function gdvf {
	$CurrentBranch = Get-Git-CurrentBranch

    nvim -p +"tabdo Gdiffsplit $CurrentBranch"
}
function gdlc {
	git diff --cached HEAD^ $args
}
function gc {
	git commit -m $args
}
function gac {
	git commit -am $args
}
function gcl {
	git clone $args
}
function gb {
	git branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate $args
}
function gbe {
	git branch -D $args
}
function gch {
	git checkout $args
}
function gcb {
	git git checkout -b $args
}
function gp {
    $alias = $MyInvocation.InvocationName
    if ($alias -ceq "gp") {
        git pull $args
    } elseif ($alias -ceq "gP"){
        git push $args
    }
}
function gf {
	$CurrentBranch = Get-Git-CurrentBranch

	git fetch && git diff --name-only ..origin/$CurrentBranch $args
}
function gst {
	git stash $args
}
function gu {
	git reset HEAD~1 --mixed $args
}
function gl {
	git log --graph --pretty=format:\"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]\" --decorate --date=relative $args
}
function gll {
	git log --graph --pretty=format:\"%C(yellow)%h%Cred%d %Creset%s%Cblue [%cn]\" --decorate --numstat $args
}

# Prompt
Invoke-Expression (&starship init powershell)

$prompt = ""
function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
    }
    $host.ui.Write($prompt)
}
