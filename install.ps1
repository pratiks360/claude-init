# install.ps1

$InstallDir = "$env:USERPROFILE\.cl-config-cli"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

# Pointing directly to your repository's raw cl-config.ps1 file
$ScriptUrl = "https://raw.githubusercontent.com/pratiks360/claude-init/main/cl-config.ps1"
$LocalScriptPath = Join-Path $InstallDir "cl-config.ps1"

Write-Host "Downloading cl-config..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $ScriptUrl -OutFile $LocalScriptPath -ErrorAction Stop

# Create the .cmd wrapper with strict ASCII encoding so CMD.exe can read it
$CmdWrapperPath = Join-Path $InstallDir "cl-config.cmd"
$CmdContent = "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%~dp0cl-config.ps1`" %*"
[System.IO.File]::WriteAllText($CmdWrapperPath, $CmdContent, [System.Text.Encoding]::ASCII)

# Add to User PATH
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notmatch [regex]::Escape($InstallDir)) {
    $NewPath = "$UserPath;$InstallDir"
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
    Write-Host "Added $InstallDir to PATH." -ForegroundColor Green
    Write-Host "Please restart your terminal to use the 'cl-config' command." -ForegroundColor Yellow
} else {
    Write-Host "cl-config is already in your PATH." -ForegroundColor Green
}

Write-Host "`nInstallation Complete! Navigate to any project folder and run 'cl-config'." -ForegroundColor Cyan
