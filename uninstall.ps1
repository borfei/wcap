"wcap - Simple and efficient screen recording utility for Windows 10 and 11"
"This is free and unencumbered software released into the public domain."; ""

$WCAP_ADMIN = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)


$WCAP_INSTALL_PATH = "$env:LOCALAPPDATA\wcap"
$WCAP_INSTALL_PROCEED = $false
$WCAP_INSTALL_REVIEW = $false

if ($PSVersionTable.PSVersion.Major -gt 5) {
	if (-not($IsWindows)) {
		Write-Error "wcap is unavailable for this platform."
		return
	}
}
if ($WCAP_ADMIN) {
    # Use Program Files as default install path if this script has administrative rights.
    # Warn the user that this script is running in Administrator mode.
    $WCAP_INSTALL_PATH = "$env:PROGRAMFILES\wcap"
    Write-Warning "This script is running with administrative rights."
}
