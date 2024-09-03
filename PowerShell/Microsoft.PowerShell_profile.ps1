# Create profile
# New-Item -Type file -Path $PROFILE -Force

# Open
# notepad $PROFILE

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
function gs {
	git status $args
}
function gd {
	git diff $args
}
function gdn {
	$CurrentBranch = Get-Git-CurrentBranch

	git diff --name-only ..origin/$CurrentBranch $args
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
function gP {
	git push $args
}
function gp {
	git pull $args
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
	git log --pretty=format:\"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --date=relative $args
}
function gll {
	git log --pretty=format:\"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --numstat $args
}
function gdlc {
	git diff --cached HEAD^ $args
}

# Prompt
Invoke-Expression (&starship init powershell)