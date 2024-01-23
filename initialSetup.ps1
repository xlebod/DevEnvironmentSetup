function global:Set-UnrestrictedPolicy {
    Set-ExecutionPolicy Unrestricted;
}

function global:Install-Chocolatey {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')); 
}

function global:Install-Terminal {
    # Install Oh my posh & posh-git
    choco install oh-my-posh -y
    Install-Module posh-git

    # Install Cascadia Cove Nerd font   
    $fontZip = "~\Downloads\CascadiaCode.zip"
    $fontFolder = "~\Downloads\CascadiaCode"
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
    Set-Content -Path $terminalsConfigJson ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/xlebod/TerminalConfig/main/settings.json'))

    # Initiate posh-git with correct theme
    if(-not((Get-Content $PROFILE -Raw) -like '*oh-my-posh*')){
        Add-Content -Path $PROFILE "oh-my-posh init pwsh --config '$($env:POSH_THEMES_PATH)\kushal.omp.json' | Invoke-Expression"
        Add-Content -Path $PROFILE "Import-Module posh-git"
    }

    Install-Module -Name Terminal-Icons -Repository PSGallery
    Install-Module -Name PSReadLine
}

function global:Install-All {
    global:Set-UnrestrictedPolicy
    global:Install-Chocolatey
    global:Install-Terminal
}
