[CmdletBinding()] param([switch]$NoRunAfterInstall, [switch]$NoModifyPATH, [switch]$NoStartupEntry)
$WcapDownloadUrl = "https://nightly.link/spiroth/wcap/workflows/wcap/main/wcap.zip"
$WcapDownloadPath = "$env:TEMP\wcap"
$WcapDownloadProgram = "curl" # available options: curl, powershell

$WcapInstallPath = "$env:LOCALAPPDATA\wcap"
$WcapInstallExecutable = "$WcapInstallPath\wcap.exe"

if ($PSVersionTable.PSVersion.Major -gt 5) {
	if (-not($IsWindows)) {
		Write-Error "This program is unavailable for non-Windows platforms."
		return
	}
} elseif ($PSVersionTable.PSVersion.Major -le 5) {
    try {
        Get-Item alias:curl
    } catch {
        Remove-Item alias:curl # workaround to download files using cURL in Powershell 5.x and older
    }
}
if (-not(Get-Command "curl" -errorAction SilentlyContinue)) {
    Write-Warning "cURL is not available, using Invoke-WebRequest as fallback."
    $WcapDownloadProgram = "powershell"
}
if (-not(Test-Path $WcapDownloadPath -PathType Container)) {
    Write-Verbose "Creating directory $WcapDownloadPath"
    $null = New-Item $WcapDownloadPath -ItemType Directory
}
if ($WcapDownloadProgram -eq "curl") {
    Push-Location $WcapDownloadPath
    Write-Verbose "Downloading $WcapDownloadUrl using cURL"
    curl -sS -L $WcapDownloadUrl -o "wcap.zip"
    Pop-Location
} elseif ($WcapDownloadProgram -eq "powershell") {
    Write-Verbose "Downloading $WcapDownloadUrl using Invoke-WebRequest"
    Invoke-WebRequest $WcapDownloadUrl -OutFile "$WcapDownloadPath\wcap.zip"
} else {
    Write-Error "No specified program to download files."
    return
}
if (-not(Test-Path $WcapInstallPath -PathType Container)) {
    Write-Verbose "Creating destination path $WcapInstallPath"
    $null = New-Item $WcapInstallPath -ItemType Directory
}
try {
    Write-Verbose "Extracting $WcapDownloadPath\wcap.zip to $WcapInstallPath"
    Expand-Archive "$WcapDownloadPath\wcap.zip" -DestinationPath $WcapInstallPath -Force
    Remove-Item $WcapDownloadPath -Recurse -Force
} catch {
    Write-Error "There was something wrong installing wcap:"
    Write-Error "   $_"
    return
}
if (-not($NoModifyPATH)) {
    $WcapEnvUserPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $WcapEnvProcessPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Process)

    if (-not($WcapEnvUserPath -split ";" -contains "$WcapInstallPath")) {
        Write-Verbose "Adding wcap to user's PATH environment variable"
        [Environment]::SetEnvironmentVariable("Path", "$WcapEnvUserPath;$WcapInstallPath", [EnvironmentVariableTarget]::User)
    }
    if (-not($WcapEnvProcessPath -split ";" -contains "$WcapInstallPath")) {
        Write-Verbose "Adding wcap to process' PATH environment variable"
        [Environment]::SetEnvironmentVariable("Path", "$WcapEnvProcessPath;$WcapInstallPath", [EnvironmentVariableTarget]::Process)
    }
}
if (-not($NoStartupEntry)) {
    $WcapRegStartupPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

    if (-not(Test-Path $WcapRegStartupPath -PathType Container)) {
        Write-Verbose "Creating registry path for startup entry"
        $null = New-Item $WcapRegStartupPath -Force
    }
    try {
        $null = Get-ItemProperty -Path $WcapRegStartupPath -Name "wcap" -ErrorAction Stop
    } catch {
        Write-Verbose "Creating startup entry for wcap"
        $null = New-ItemProperty -Path $WcapRegStartupPath -Name "wcap" -Value $WcapInstallExecutable -PropertyType String -Force
    }
}
if (-not($NoRunAfterInstall)) {
    Write-Verbose "Starting $WcapInstallExecutable"
    Start-Process $WcapInstallExecutable
}