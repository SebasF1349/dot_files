# https://www.reddit.com/r/neovim/comments/1iyurr1/my_updateinstall_neovim_nightly_powershell_script/

function Test-IsAdmin {
  return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Update-Neovim {
  if (!(Test-IsAdmin)) { 
    Write-Error 'Must run as admin'
      return
  }
  if (Get-Process nvim -ErrorAction SilentlyContinue) {
    Write-Error 'First close all nvim instances'
      return
  }
  if (Test-Path -Path '~\Downloads\nvim-win64.zip') {
    Remove-Item ~\Downloads\nvim-win64.zip # incase earlier failure left it here
  }
  if (Test-Path -Path '~\Downloads\nvim-win64') {
    Remove-Item ~\Downloads\nvim-win64 -Force -Recurse # incase earlier failure left it here
  }
  Invoke-WebRequest https://github.com/neovim/neovim/releases/download/nightly/nvim-win64.zip -OutFile ~\Downloads\nvim-win64.zip
    Expand-Archive ~\Downloads\nvim-win64.zip -DestinationPath ~\Downloads\nvim-win64
    Remove-Item ~\Downloads\nvim-win64.zip
    if (Test-Path -Path 'C:\Program Files\Neovim') {
      Get-ChildItem 'C:\Program Files\Neovim' | Remove-Item -Recurse -Force
    }
    else {
      $null = New-Item -Type Directory 'C:\Program Files\Neovim'
    }
  Move-Item ~\Downloads\nvim-win64\nvim-win64\* -Destination 'C:\Program Files\Neovim'
    Remove-Item ~\Downloads\nvim-win64 -Force -Recurse
}
