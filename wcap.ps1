"wcap - Simple and efficient screen recording utility for Windows 10 and 11"
"This is free and unencumbered software released into the public domain."; ""

function Write-Error($message) {
    # I had to use this function to suppress the "Write-Error" message from the command-line.
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
    Write-Output "  - The PATH environment variable will be modified."; ""
    $REVIEW_OK = (Read-Host "Begin the installation? (Y/n/d/o)").ToLower()

    if ($REVIEW_OK -eq "y") {
        Write-Output "Installation started, do not close this process!"
        $WCAP_INSTALL_REVIEW = $true
        continue
    } elseif ($REVIEW_OK -eq "n") {
        Write-Output "Installation aborted, exiting with code 0."
        exit 0
        break
    } elseif ($REVIEW_OK -eq "d") {
        $WCAP_DOWNLOAD_PATH = Read-Host "Download to [$WCAP_DOWNLOAD_PATH]"
        continue
    } elseif ($REVIEW_OK -eq "o") {
        if (-not($WCAP_ADMIN)) {
            Write-Warning "To install wcap under Program Files, run this script with administrative rights."
        }

        $WCAP_INSTALL_PATH = Read-Host "Install at [$WCAP_INSTALL_PATH]"
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

Write-Output "Modifying the PATH environment variable"

if ($WCAP_ADMIN) {
    [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$WCAP_INSTALL_PATH", [EnvironmentVariableTarget]::Machine)
} else {
    [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$WCAP_INSTALL_PATH", [EnvironmentVariableTarget]::User)
}

"wcap is installed successfully, restart your shell session to apply changes for PATH."