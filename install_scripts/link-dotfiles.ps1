function make-file-link ($target, $link) {
    New-Item -ItemType SymbolicLink -Path $link -Value (Get-Item $target) | Out-Null
}

function make-dir-link ($target, $link) {
    New-Item -ItemType Junction -Path $link -Target (Get-Item $target) | Out-Null
}

$config_dirs = @(
    "$env:USERPROFILE\.config\"
)

$file_links = @{
    "$env:USERPROFILE\.config\starship.toml" = "..\starship\starship.toml"
    "$env:USERPROFILE\.vimrc" = "..\vim\.vimrc"
    "C:\Program Files\WezTerm\wezterm.lua" = "..\wezterm\wezterm.lua"
    "C:\Program Files\WezTerm\keys.lua" = "..\wezterm\keys.lua"
    "C:\Program Files\WezTerm\utils.lua" = "..\wezterm\utils.lua"
    "C:\Program Files\WezTerm\wallpaper_clean_mini.jpeg" = "..\wallpaper\wallpaper_clean_mini.jpeg"
    "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" = "..\windows_terminal\settings.json"
    "$env:USERPROFILE\.gitconfig" = "..\git\.gitconfig"
}

$dir_links = @{
    "$env:LocalAppData\nvim\" = "..\nvim\" 
    "$env:USERPROFILE\.glzr\" = "..\.glzr\"
    "$env:APPDATA\bat\" = "..\bat\"
}

# LibreOffice?
# Powershell is in D?
# be careful with VSCode as it sync online

foreach ($link in $config_dirs) {
    if (!(Test-Path $link -PathType Container)) {
        New-Item -Path $link -ItemType "directory"
    }
}

foreach ($link in $file_links.Keys) {
    $target = $file_links[$link]
    if (!(Test-Path $link -PathType Leaf)) {
        make-file-link $file_links[$link] $link
        Write-Output "Created link to $target"
    }
    Write-Output "Link to $target already created"
}

foreach ($link in $dir_links.Keys) {
    $target = $dir_links[$link]
    if (!(Test-Path $link -PathType Container)) {
        make-dir-link $dir_links[$link] $link
        Write-Output "Created link to $target"
    }
    Write-Output "Link to $target already created"
}
