# https://github.com/jtroo/kanata/discussions/193#discussioncomment-11130086

# Specify the repository and file name
$repo = 'jtroo/kanata'
$fileName = 'kanata_gui.exe'
$installDir = 'C:\Program Files\Kanata'
$installPath = Join-Path -Path $installDir -ChildPath $fileName

# Get the latest release information using GitHub API
$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest"
$version = $latestRelease.tag_name

# Create the download link by replacing the placeholder with the version
$downloadLink = "https://github.com/$repo/releases/download/$version/$fileName"

# Create the installation directory if it doesn't exist
New-Item -ItemType Directory -Path $installDir -Force

# Download
Write-Output "Downloading kanata_gui.exe..."
Invoke-WebRequest -Uri $downloadLink -OutFile $installPath -ErrorAction Stop

# Create shortcut in the Startup folder
$startupFolder = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path -Path $startupFolder -ChildPath 'kanata_gui.lnk'

# Create WScript Shell Object
$WScriptShell = New-Object -ComObject WScript.Shell

# Create the shortcut
$Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $installPath
$Shortcut.Description = "Kanata GUI"
$Shortcut.WorkingDirectory = $installDir
$Shortcut.Save()

Write-Output "Installation complete! Kanata GUI will start automatically with Windows."
Write-Output "Now copy the `kanata.kbd` in the `C:\Program Files\Kanata` folder."

# Open `C:\Program Files\Kanata` folder
Start-Process -FilePath $installDir
