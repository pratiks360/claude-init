# install.ps1

$InstallDir = "$env:USERPROFILE\.cl-config-cli"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

# Pointing directly to your repository's raw cl-config.ps1 file
$ScriptUrl = "https://raw.githubusercontent.com/pratiks360/claude-init/main/cl-config.ps1"
$LocalScriptPath = Join-Path $InstallDir "cl-config.ps1"

Write-Host "Downloading cl-config..." -ForegroundColor Cyan

# Added -ErrorAction Stop so the installation halts if the download fails (no empty folders)
Invoke-WebRequest -Uri $ScriptUrl -OutFile $LocalScriptPath -ErrorAction Stop

# Create the .cmd wrapper
$CmdWrapperPath = Join-Path $InstallDir "cl-config.cmd"
$CmdContent = "@powershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0cl-config.ps1`" %*"
Set-Content -Path $CmdWrapperPath -Value $CmdContent

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
