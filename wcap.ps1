"wcap - Simple and efficient screen recording utility for Windows 10 and 11"
"This is free and unencumbered software released into the public domain."; ""

function Write-Error($message) {
    # Had to use this function to suppress the "Write-Error" message from the command-line.
    [Console]::ForegroundColor = 'red'
    [Console]::Error.WriteLine("ERROR: $message")
    [Console]::ResetColor()
}

$WCAP_ADMIN = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$WCAP_DOWNLOAD_URL = "https://nightly.link/spiroth/wcap/workflows/wcap/main/wcap.zip"
$WCAP_DOWNLOAD_PATH = "$env:TEMP\wcap"
$WCAP_DOWNLOAD_EXEC = "curl" # Available options: curl, powershell

$WCAP_INSTALL_PATH = "$env:LOCALAPPDATA\wcap"
$WCAP_INSTALL_PROCEED = $false
$WCAP_INSTALL_REVIEW = $false

$WCAP_EXTRA_ADD_PATH = $true
$WCAP_EXTRA_INCLUDE_UNINSTALL = $false # Temporarily disabled in the meantime
$WCAP_EXTRA_RUN_AFTER_INSTALL = $false

if (-not($IsWindows)) {
	Write-Error "wcap is unavailable for this platform."
	exit 1
}
if (-not(Get-Command "curl" -errorAction SilentlyContinue)) {
    Write-Warning "cURL is not available, using Invoke-WebRequest as fallback."
    $WCAP_DOWNLOAD_EXEC = "powershell"
}
if ($WCAP_ADMIN) {
    # Use Program Files as default install path if this script has administrative rights.
    # Warn the user that this script is running in Administrator mode.
    $WCAP_INSTALL_PATH = "$env:PROGRAMFILES\wcap"
    Write-Warning "This script is running with administrative rights."
}

$WCAP_INSTALL_PROCEED = if ((Read-Host "You are now installing wcap, proceed? (Y/n)").ToLower() -eq "y") { $true } else { $false }

if (-not($WCAP_INSTALL_PROCEED)) {
    Write-Output "Installation aborted, exiting with code 0."
    exit 0
} else {
    Write-Output "" # A newline should be expected before reviewing.
}

while (-not($WCAP_INSTALL_REVIEW)) {
    Write-Output "Before starting the actual installation, review the tasks first:"
    Write-Output "  - URL: $WCAP_DOWNLOAD_URL"
    Write-Output "  - Download to: $WCAP_DOWNLOAD_PATH"
    Write-Output "  - Install at: $WCAP_INSTALL_PATH"
    Write-Output "Review the additional tasks as well:"
    Write-Output "  - Add to PATH environment variable: $WCAP_EXTRA_ADD_PATH"
    # Write-Output "  - Include uninstall script: $WCAP_EXTRA_INCLUDE_UNINSTALL"
    Write-Output "  - Run program after installation: $WCAP_EXTRA_RUN_AFTER_INSTALL"; ""
    $REVIEW_OK = (Read-Host "Begin the installation? (Y/n/c)").ToLower()

    if ($REVIEW_OK -eq "y") {
        ""; Write-Output "Installation started, do not close this process!"
        $WCAP_INSTALL_REVIEW = $true
        continue
    } elseif ($REVIEW_OK -eq "n") {
        Write-Output "Installation aborted, exiting with code 0."
        exit 0
        break
    } elseif ($REVIEW_OK -eq "c") {
        $WCAP_OLD_DOWNLOAD_PATH = $WCAP_DOWNLOAD_PATH
        $WCAP_OLD_INSTALL_PATH = $WCAP_INSTALL_PATH
        
        $WCAP_DOWNLOAD_PATH = Read-Host "Download to [$WCAP_DOWNLOAD_PATH]"
        $WCAP_INSTALL_PATH = Read-Host "Install at [$WCAP_INSTALL_PATH]"

        $WCAP_EXTRA_ADD_PATH = if ((Read-Host "Add wcap to PATH environment variable? (Y/n)").ToLower() -eq "y") { $true } else { $false }
        # $WCAP_EXTRA_INCLUDE_UNINSTALL = if ((Read-Host "Include uninstall script? (Y/n)").ToLower() -eq "y") { $true } else { $false }
        $WCAP_EXTRA_RUN_AFTER_INSTALL = if ((Read-Host "Run program after installation? (Y/n)").ToLower() -eq "y") { $true } else { $false }; ""

        if (-not($WCAP_DOWNLOAD_PATH)) {
            $WCAP_DOWNLOAD_PATH = $WCAP_OLD_DOWNLOAD_PATH
        }
        if (-not($WCAP_INSTALL_PATH)) {
            $WCAP_INSTALL_PATH = $WCAP_OLD_INSTALL_PATH
        }

        continue
    }
}

if (-not(Test-Path $WCAP_DOWNLOAD_PATH -PathType Container)) {
    $null = New-Item $WCAP_DOWNLOAD_PATH -ItemType Directory
}

Write-Output "Downloading wcap from $WCAP_DOWNLOAD_URL"

if ($WCAP_DOWNLOAD_EXEC -eq "curl") {
    Push-Location $WCAP_DOWNLOAD_PATH
    curl -sS -L $WCAP_DOWNLOAD_URL -o "wcap.zip"
    Pop-Location
} elseif ($WCAP_DOWNLOAD_EXEC -eq "powershell") {
    Invoke-WebRequest $WCAP_DOWNLOAD_URL -OutFile "$WCAP_DOWNLOAD_PATH\wcap.zip"
} else {
    Write-Error "Invalid download option: $WCAP_DOWNLOAD_EXEC"
    exit 1
}

Write-Output "Installing wcap to $WCAP_INSTALL_PATH"

if (-not(Test-Path $WCAP_INSTALL_PATH -PathType Container)) {
    $null = New-Item $WCAP_INSTALL_PATH -ItemType Directory
}

Expand-Archive -Path "$WCAP_DOWNLOAD_PATH\wcap.zip" -DestinationPath $WCAP_INSTALL_PATH -Force
Remove-Item $WCAP_DOWNLOAD_PATH -Recurse -Force

if ($WCAP_EXTRA_ADD_PATH) {
    Write-Output "Adding wcap to the PATH environment variable"
    $WCAP_ENV_SCOPE = if ($WCAP_ADMIN) { [EnvironmentVariableTarget]::Machine } else { [EnvironmentVariableTarget]::User }
    $WCAP_ENV_PATH = [Environment]::GetEnvironmentVariable("Path", $WCAP_ENV_SCOPE)

    if (-not($WCAP_ENV_PATH -split ";" -contains "$WCAP_INSTALL_PATH")) {
        [Environment]::SetEnvironmentVariable("Path", "$WCAP_ENV_PATH;$WCAP_INSTALL_PATH", $WCAP_ENV_SCOPE)
        Write-Warning "Restart your shell session to save changes for PATH environment variable."
    } else {
        # Warn user that the program is already accessible via PATH and is no longer needed to do this task.
        Write-Warning "wcap has already been added into the PATH environment variable."
    }
}
if ($WCAP_EXTRA_INCLUDE_UNINSTALL) {
    Write-Output "Downloading uninstall script from URLs"
    $WCAP_UNINSTALL_URL = "https://dl.dropboxusercontent.com/s/3pxeygqqw519qzv/uninstall.ps1"

    if ($WCAP_DOWNLOAD_EXEC -eq "curl") {
        Push-Location $WCAP_INSTALL_PATH
        curl -sS -L $WCAP_UNINSTALL_URL -o "uninstall.ps1"
        Pop-Location
    } elseif ($WCAP_DOWNLOAD_EXEC -eq "powershell") {
        Invoke-WebRequest $WCAP_UNINSTALL_URL -OutFile "$WCAP_INSTALL_PATH\uninstall.ps1"
    } else {
        Write-Error "Invalid download option: $WCAP_DOWNLOAD_EXEC"
        exit 1
    }

    Write-Output "Registering uninstall script to the program information"
    $WCAP_REGISTRY_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\wcap"
    $WCAP_REGISTRY_COMMENTS = "wcap"
    $WCAP_REGISTRY_DISPLAY_ICON = "$WCAP_INSTALL_PATH\wcap.exe,0"
    $WCAP_REGISTRY_DISPLAY_NAME = "wcap"
    $WCAP_REGISTRY_INSTALL_DIR = "$WCAP_INSTALL_PATH"
    $WCAP_REGISTRY_NO_MODIFY = 1
    $WCAP_REGISTRY_NO_REPAIR = 1
    $WCAP_REGISTRY_PUBLISHER = "spir0th"
    $WCAP_REGISTRY_UNINSTALL = "`"$env:SystemRoot\System32\cmd.exe`" /c `"$WCAP_INSTALL_PATH\uninstall.cmd`""
    $WCAP_REGISTRY_URL_INFO = "https://github.com/spiroth/wcap"

    if ($WCAP_ADMIN) {
        # Use the HKEY_LOCAL_MACHINE key to store the information on system-wide instead
        $WCAP_REGISTRY_PATH = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\wcap"
    }
    if (-not(Test-Path $WCAP_REGISTRY_PATH -PathType Container)) {
        $null = New-Item $WCAP_REGISTRY_PATH -Force
    }

    $null = New-ItemProperty -Path $WCAP_REGISTRY_PATH -Name "Comments" -Value $WCAP_REGISTRY_COMMENTS -PropertyType String -Force
    $null = New-ItemProperty -Path $WCAP_REGISTRY_PATH -Name "DisplayIcon" -Value $WCAP_REGISTRY_DISPLAY_ICON -PropertyType String -Force
    $null = New-ItemProperty -Path $WCAP_REGISTRY_PATH -Name "DisplayName" -Value $WCAP_REGISTRY_DISPLAY_NAME -PropertyType String -Force
    $null = New-ItemProperty -Path $WCAP_REGISTRY_PATH -Name "InstallLocation" -Value $WCAP_REGISTRY_INSTALL_DIR -PropertyType String -Force
    $null = New-ItemProperty -Path $WCAP_REGISTRY_PATH -Name "NoModify" -Value $WCAP_REGISTRY_NO_MODIFY -PropertyType Dword -Force
    $null = New-ItemProperty -Path $WCAP_REGISTRY_PATH -Name "NoRepair" -Value $WCAP_REGISTRY_NO_REPAIR -PropertyType Dword -Force
    $null = New-ItemProperty -Path $WCAP_REGISTRY_PATH -Name "Publisher" -Value $WCAP_REGISTRY_PUBLISHER -PropertyType String -Force
    $null = New-ItemProperty -Path $WCAP_REGISTRY_PATH -Name "UninstallString" -Value $WCAP_REGISTRY_UNINSTALL -PropertyType String -Force
    $null = New-ItemProperty -Path $WCAP_REGISTRY_PATH -Name "URLInfoAbout" -Value $WCAP_REGISTRY_URL_INFO -PropertyType String -Force
}
if ($WCAP_EXTRA_RUN_AFTER_INSTALL) {
    Write-Output "Starting wcap"
    start "$WCAP_INSTALL_PATH\wcap.exe"
}

""; "wcap is installed successfully, exiting."
