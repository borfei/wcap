"wcap - Simple and efficient screen recording utility for Windows 10 and 11"
"This is free and unencumbered software released into the public domain."; ""

$WCAP_IS_ADMIN = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$WCAP_INSTALL_PATH = $null

$WCAP_UNINSTALL_PROCEED = $false
$WCAP_UNINSTALL_REVIEW = $false

$WCAP_EXTRA_REMOVE_PATH = $true
$WCAP_EXTRA_REMOVE_STARTUP = $true

if ($PSVersionTable.PSVersion.Major -gt 5) {
	if (-not($IsWindows)) {
		Write-Error "wcap is unavailable for this platform."
		return
	}
}
if (Test-Path "$env:LOCALAPPDATA\wcap\wcap.exe" -PathType Leaf) {
    $WCAP_INSTALL_PATH = "$env:LOCALAPPDATA\wcap"
} elseif (Test-Path "$env:PROGRAMFILES\wcap\wcap.exe" -PathType Leaf -and $WCAP_IS_ADMIN) {
    $WCAP_INSTALL_PATH = "$env:PROGRAMFILES\wcap"
} elseif (Test-Path "wcap.exe" -PathType Leaf) {
    $WCAP_INSTALL_PATH = Get-Location
} else {
    Write-Output "No existing installation of wcap has been detected, exiting."
    return
}

$WCAP_UNINSTALL_PROCEED = if ((Read-Host "Are you sure you want to uninstall wcap? (Y/n)").ToLower() -eq "y") { $true } else { $false }

if (-not($WCAP_UNINSTALL_PROCEED)) {
    return
} else {
    Write-Output "" # A newline should be expected before reviewing.
    Write-Output "Before uninstalling the program, review the tasks first:"
}

while (-not($WCAP_UNINSTALL_REVIEW)) {
    Write-Output "  - Remove program at: $WCAP_INSTALL_PATH"
    Write-Output "Review the additional tasks as well:"
    Write-Output "  - Remove from PATH environment variable: $WCAP_EXTRA_REMOVE_PATH"
    Write-Output "  - Remove created startup entry: $WCAP_EXTRA_REMOVE_STARTUP"; ""
    $REVIEW_OK = (Read-Host "Begin the uninstallation? (Y/n/c)").ToLower()

    if ($REVIEW_OK -eq "y") {
        ""; Write-Output "Uninstall started, do not close this process!"
        $WCAP_UNINSTALL_REVIEW = $true
        continue
    } elseif ($REVIEW_OK -eq "n") {
        Write-Output "Uninstall aborted, exiting."
        return
        break
    } elseif ($REVIEW_OK -eq "c") {
        $WCAP_EXTRA_REMOVE_PATH = if ((Read-Host "Remove wcap from PATH environment variable? (Y/n)").ToLower() -eq "y") { $true } else { $false }
        $WCAP_EXTRA_REMOVE_STARTUP = if ((Read-Host "Delete startup entry for wcap? (Y/n)").ToLower() -eq "y") { $true } else { $false }
        continue
    }
}

if ($WCAP_EXTRA_REMOVE_PATH) {
    Write-Output "Removing wcap from the PATH environment variable"
    $WCAP_ENV_SCOPE = if ($WCAP_IS_ADMIN) { [EnvironmentVariableTarget]::Machine } else { [EnvironmentVariableTarget]::User }
    $WCAP_ENV_PATH = [Environment]::GetEnvironmentVariable("Path", $WCAP_ENV_SCOPE)

    if ($WCAP_ENV_PATH -split ";" -contains "$WCAP_INSTALL_PATH") {
        $WCAP_ENV_PATH = ($WCAP_ENV_PATH.Split(";") | Where-Object { $_ -ne $WCAP_INSTALL_PATH }) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $WCAP_ENV_PATH, $WCAP_ENV_SCOPE)
        Write-Warning "Restart your shell session to save changes for PATH environment variable."
    } else {
        # Warn user that the program is not in PATH anymore and is no longer needed to do this task.
        Write-Warning "wcap has already been removed from the PATH environment variable."
    }
}
if ($WCAP_EXTRA_REMOVE_STARTUP) {
    Write-Output "Removing startup entry for wcap"
    $WCAP_REGISTRY_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

    try {
        $null = Remove-ItemProperty -Path $WCAP_REGISTRY_PATH -Name "wcap" -ErrorAction Stop
    } catch {
        Write-Warning "No startup entries are created for wcap."
    }
}

Write-Verbose "Remove wcap from Apps & Features"
$WCAP_REGISTRY_PATH = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\wcap"
$WCAP_ADMIN_REGISTRY_PATH = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\wcap"

if (Test-Path $WCAP_REGISTRY_PATH -PathType Container) {
    Remove-Item $WCAP_REGISTRY_PATH -Recurse -Force
}
if (Test-Path $WCAP_ADMIN_REGISTRY_PATH -PathType Container) {
    Remove-Item $WCAP_ADMIN_REGISTRY_PATH -Recurse -Force
}

Write-Verbose "Create delete_wcap.cmd at $env:TEMP"

if (Test-Path "$env:TEMP\delete_wcap.cmd" -PathType Leaf) {
    Remove-Item "$env:TEMP\delete_wcap.cmd" -Force
}

Add-Content "$env:TEMP\delete_wcap.cmd" -Value "@echo off"
Add-Content "$env:TEMP\delete_wcap.cmd" -Value "title"
Add-Content "$env:TEMP\delete_wcap.cmd" -Value "rd /s /q $WCAP_INSTALL_PATH"
Add-Content "$env:TEMP\delete_wcap.cmd" -Value "echo wcap is uninstalled successfully."
Add-Content "$env:TEMP\delete_wcap.cmd" -Value "pause >nul"

Write-Output "" # Expect a newline before running the deletion script
Set-Location (Get-Item $PWD).Parent
Start-Process "cmd" -ArgumentList "/c $env:TEMP\delete_wcap.cmd" -WorkingDirectory "$env:TEMP"
Remove-Item -Path $MyInvocation.MyCommand.Source