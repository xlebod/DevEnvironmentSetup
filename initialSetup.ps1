$global:DownloadBasePath = "~\Downloads\"
function global:Set-UnrestrictedPolicy {
    Set-ExecutionPolicy Unrestricted;
}

function global:Install-Chocolatey {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')); 
}

# Sets up terminal environment and style:
# 
# Color theme
function global:Install-Terminal {
    # Install Oh my posh & posh-git
    choco install oh-my-posh -y
    Install-Module posh-git

    # Install Commit mono font   
    $fontZip = $global:DownloadBasePath + "CascadiaCode.zip"
    $fontFolder = $global:DownloadBasePath + "CascadiaCode"
    $fontFile = "$($fontFolder)\CaskaydiaCoveNerdFontMono-SemiBold.ttf"
    Invoke-WebRequest -URI "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip" -OutFile $fontZip
    Expand-Archive $fontZip -DestinationPath $fontFolder

    $fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
    $fileName = Get-ChildItem $fontFile
    if(-not(Test-Path -Path "C:\Windows\fonts\$($fileName.Name)")) {
        Write-Output "Installing $($fileName.Name)"
        $fonts.CopyHere($fileName.FullName)
        Copy-Item $fileName C:\Windows\fonts
    }

    # Change setting of Windows Terminal
    $terminalsConfigJson = "$($env:LOCALAPPDATA)\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    Set-Content -Path $terminalsConfigJson ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/xlebod/DevEnvironmentSetup/main/settings.json'))

    # Initiate posh-git with correct theme
    if(-not((Get-Content $PROFILE -Raw) -like '*oh-my-posh*')){
        Add-Content -Path $PROFILE "oh-my-posh init pwsh --config '$($env:POSH_THEMES_PATH)\kushal.omp.json' | Invoke-Expression"
        Add-Content -Path $PROFILE "Import-Module posh-git"
    }

    Install-Module -Name Terminal-Icons -Repository PSGallery
    Install-Module -Name PSReadLine
}

# Installs applications:
#   -> Google Chrome
#   -> Git
#   -> NVM
#   -> Visual Studio Code
#   -> 7-Zip
#   -> VLC Media Player
function global:Install-Apps {
    choco install googlechrome -y
    choco install git -y
    choco install nvm -y
    choco install vscode -y
    choco install 7zip -y
    choco install vlc -y
}

# Installs Visual Studio 2022 Professional with worflows:
#   -> ASP.NET and web developement
#   -> .NET desktop developement
# Left over files:
#   -> Temp file: %temp%\.vsconfig2022
function global:Install-VisualStudio {

    $year = "2022"
    $version = "Professional"
    $visualStudioId = "Microsoft.VisualStudio." + $year +'.' + $version
    $vsConfigPath = "$($env:TEMP)\.vsconfig2022"

    # Config file for wanted workflows from Visual Studio Installer
    Set-Content -Path $vsConfigPath ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/xlebod/DevEnvironmentSetup/main/.vsconfig2022'))

    winget install --id $visualStudioId --override "--passive --config $($vsConfigPath)"
}

# Silently installs Rider
# Left over files: 
#   ->  ~\Downloads\rider.exe (~800MB)
#   -> Temp file: %temp%\silent.config
function global:Install-Rider {
    param (
        [switch]$Force
    )
    $installationDirectory = "'C:\Program Files (x86)\JetBrains\Rider'"

    # 2023.3.3 - Update URI for new versions
    $exeUri = "https://download.jetbrains.com/rider/JetBrains.Rider-2023.3.3.exe?_ga=2.37755747.1914030267.1706020452-624681219.1706020451"
    $silentConfigUri = "https://download.jetbrains.com/rider/silent.config?_ga=2.209802325.1739794530.1706020312-619940658.1706020312"
    $exePath = $global:DownloadBasePath + "rider.exe"
    $configPath = "$($env:TEMP)\silent.config"
    Write-Output "Switching to silent download to increase download speed."
    $ProgressPreference = 'SilentlyContinue'
    if(-not(Test-Path $exePath) -or $Force){
        Write-Output "Starting Rider download..."
        Invoke-WebRequest -URI $exeUri -OutFile $exePath
        Write-Output "Finished downloading Rider!"
    }
    else {
        Write-Output "rider.exe is present. If you want to force re-download use -Force flag"
    }
    if(-not(Test-Path $configPath) -or $Force){
        Write-Output "Starting silent.config download..."
        Invoke-WebRequest -URI $silentConfigUri -OutFile $configPath
        Write-Output "Finished downloading silent.config!"
    }
    else {
        Write-Output "silent.config is present. If you want to force re-download use -Force flag"
    }
    $ProgressPreference = 'Continue'
    Write-Output "Returned to verbose downloading"
    $installRider = "$($exePath) /S /CONFIG=$($configPath) /LOG=$($global:DownloadBasePath + "RiderInstall.log") /D=$($installationDirectory)"
    Write-Output "Running command: $($installRider)"
    Invoke-Expression $installRider
}

function global:Setup-Tere {
    # Prerequisites: 
    #   -> Download tere.exe : https://github.com/mgunyho/tere/releases/latest
    #   -> Place in C:\Program Files\tere
    $tereProfileSetup = 
@'
Function Add-PathVariable {
    param (
        [string]$addPath
    )
    if (Test-Path $addPath){
        $regexAddPath = [regex]::Escape($addPath)
        $arrPath = $env:Path -split ';' | Where-Object {$_ -notMatch 
"^$regexAddPath\\?"}
        $env:Path = ($arrPath + $addPath) -join ';'
    } else {
        Throw "'$addPath' is not a valid path."
    }
}

function Invoke-Tere() {
    $result = . (Get-Command -CommandType Application tere) $args
    if ($result) {
        Set-Location $result
    }
}

Add-PathVariable -addPath 'C:\Program Files\tere'
Set-Alias tere Invoke-Tere
'@

    if(-not((Get-Content $PROFILE -Raw) -like '*Invoke-Tere*')){
        Add-Content -Path $PROFILE $tereProfileSetup
    }
    else {
        Write-Output "Tere alias already present in profile!"
    }
}



function global:Install-All {
    global:Set-UnrestrictedPolicy
    global:Install-Chocolatey
    global:Install-Terminal
    global:Install-Apps
    # global:Install-VisualStudio
    # global:Install-Rider
    # global:Setup-Tere   # DO NOT ENABLE THIS UNLESS YOU HAVE COMPLETED THE PREREQUISITES!
}
