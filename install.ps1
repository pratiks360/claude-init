# install.ps1

# Define where the CLI will live on the machine
$InstallDir = "$env:USERPROFILE\.cl-config-cli"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

# Replace this URL with the raw GitHub link to your cl-config.ps1 file
$ScriptUrl = "https://raw.githubusercontent.com/YOUR_GITHUB_USER/YOUR_REPO/main/cl-config.ps1"
$LocalScriptPath = Join-Path $InstallDir "cl-config.ps1"

Write-Host "Downloading cl-config..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $ScriptUrl -OutFile $LocalScriptPath

# Create a .cmd wrapper. This allows you to type 'cl-config' in Command Prompt OR PowerShell.
$CmdWrapperPath = Join-Path $InstallDir "cl-config.cmd"
$CmdContent = "@powershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0cl-config.ps1`" %*"
Set-Content -Path $CmdWrapperPath -Value $CmdContent

# Add to User PATH if it doesn't already exist
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
