# install.ps1

$InstallDir = "$env:USERPROFILE\.cl-config-cli"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

$ScriptUrl = "https://raw.githubusercontent.com/pratiks360/claude-init/main/cl-config.ps1"
$ProxyUrl = "https://raw.githubusercontent.com/pratiks360/claude-init/main/universal-proxy.js"

$LocalScriptPath = Join-Path $InstallDir "cl-config.ps1"
$LocalProxyPath = Join-Path $InstallDir "universal-proxy.js"

Write-Host "Downloading cl-config..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $ScriptUrl -OutFile $LocalScriptPath -ErrorAction Stop

Write-Host "Downloading universal proxy engine..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $ProxyUrl -OutFile $LocalProxyPath -ErrorAction Stop

# Create the .cmd wrapper
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
