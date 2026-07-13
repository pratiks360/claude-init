# cl-config.ps1
param()

$globalClaudeDir = "$env:USERPROFILE\.claude"
$localClaudeDir = Join-Path $PWD ".claude"
$globalConfigPath = Join-Path $globalClaudeDir "settings.json"
$localConfigPath = Join-Path $localClaudeDir "settings.json"

Write-Host "=== Claude Code Local Configurator (cl-config) ===" -ForegroundColor Cyan

# 1. Provider Selection
Write-Host "`nSelect LLM Provider for this project:"
Write-Host "1. Anthropic"
Write-Host "2. OpenRouter"
Write-Host "3. NVIDIA NIM"
$providerChoice = Read-Host "Enter choice (1-3)"

$provider = switch ($providerChoice) {
    '1' { "anthropic" }
    '2' { "openrouter" }
    '3' { "nvidia-nim" }
    Default { "anthropic" }
}
Write-Host "Selected Provider: $provider" -ForegroundColor Green

# 2. Token Handling
$envToken = [Environment]::GetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", "User")
$tokenToUse = $null

if ($envToken) {
    $useExisting = Read-Host "`nFound global ANTHROPIC_AUTH_TOKEN. Inherit for this project? (Y/n)"
    if ($useExisting -eq "" -or $useExisting.ToLower() -eq 'y') {
        $tokenToUse = $envToken
    } else {
        $tokenToUse = Read-Host "Enter new API token"
    }
} else {
    $tokenToUse = Read-Host "`nNo global token found. Enter API token for $provider"
}

# 3. Handle Global MCPs & Skills
$localSettings = @{
    provider = $provider
    token = $tokenToUse
    mcp_servers = @{}
    skills = @()
}

if (Test-Path $globalConfigPath) {
    $globalSettings = Get-Content $globalConfigPath | ConvertFrom-Json
    
    if ($globalSettings.mcp_servers -or $globalSettings.skills) {
        $pullGlobal = Read-Host "`nGlobal MCP servers/skills found. Pull them into the current project? (Y/n)"
        if ($pullGlobal -eq "" -or $pullGlobal.ToLower() -eq 'y') {
            if ($globalSettings.mcp_servers) { $localSettings.mcp_servers = $globalSettings.mcp_servers }
            if ($globalSettings.skills) { $localSettings.skills = $globalSettings.skills }
            Write-Host "Inherited global MCPs and skills." -ForegroundColor Green
        }
    }
} else {
    Write-Host "`nNo global settings.json found at $globalClaudeDir" -ForegroundColor Yellow
}

# 4. Generate Local Configuration
if (-not (Test-Path $localClaudeDir)) {
    New-Item -ItemType Directory -Force -Path $localClaudeDir | Out-Null
}

# Write settings.json
$localSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $localConfigPath

# Optional: Write a local .env file if Claude Code prefers environment variables per project
$envContent = "ANTHROPIC_AUTH_TOKEN=$tokenToUse"
Set-Content -Path (Join-Path $PWD ".env") -Value $envContent

Write-Host "`nSuccess! Local project configured at $localClaudeDir" -ForegroundColor Cyan
