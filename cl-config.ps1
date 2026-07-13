# cl-config.ps1
param()

$globalClaudeDir = "$env:USERPROFILE\.claude"
$globalConfigPath = Join-Path $globalClaudeDir "settings.json"
$localClaudeDir = Join-Path $PWD ".claude"
$localConfigPath = Join-Path $localClaudeDir "settings.json"

Write-Host "=== Claude Code Local Configurator (cl-config) ===" -ForegroundColor Cyan

$localSettings = [ordered]@{
    env = @{}
}

# 1. Load Global Settings
$globalSettings = $null
if (Test-Path $globalConfigPath) {
    try {
        $globalSettings = Get-Content $globalConfigPath -Raw | ConvertFrom-Json
        Write-Host "Loaded global settings from $globalConfigPath" -ForegroundColor DarkGray
    } catch {
        Write-Host "Failed to parse global settings.json. Starting fresh." -ForegroundColor Yellow
    }
}

# 2. Provider & Token Selection
Write-Host "`nSelect LLM Provider for this project:"
Write-Host "1. Anthropic (Default)"
Write-Host "2. OpenRouter"
Write-Host "3. NVIDIA NIM"
$providerChoice = Read-Host "Enter choice (1-3)"

$tokenToUse = ""
$existingGlobalToken = $null

if ($globalSettings.env) {
    if ($globalSettings.env.ANTHROPIC_AUTH_TOKEN) { $existingGlobalToken = $globalSettings.env.ANTHROPIC_AUTH_TOKEN }
    elseif ($globalSettings.env.ANTHROPIC_API_KEY) { $existingGlobalToken = $globalSettings.env.ANTHROPIC_API_KEY }
}

if ($existingGlobalToken) {
    $useExisting = Read-Host "`nFound global token in settings.json. Inherit for this project? (Y/n)"
    if ($useExisting -eq "" -or $useExisting.ToLower() -eq 'y') {
        $tokenToUse = $existingGlobalToken
    }
}

if (-not $tokenToUse) {
    $tokenToUse = Read-Host "`nEnter API token for the selected provider"
}

# Populate the env block
switch ($providerChoice) {
    '2' { 
        # OpenRouter
        $localSettings.env["ANTHROPIC_BASE_URL"] = "https://openrouter.ai/api"
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = $tokenToUse
        $localSettings.env["ANTHROPIC_API_KEY"] = ""
        $modelToUse = Read-Host "Enter OpenRouter model (e.g., openai/gpt-oss-120b:free)"
        if ($modelToUse) { 
            # Override background task requests
            $localSettings.env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_CUSTOM_MODEL_OPTION"] = $modelToUse
        }
    }
    '3' {
        # NVIDIA NIM
        $localSettings.env["ANTHROPIC_BASE_URL"] = "https://integrate.api.nvidia.com/v1"
        $localSettings.env["ANTHROPIC_API_KEY"] = $tokenToUse
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = ""
        $modelToUse = Read-Host "Enter NVIDIA NIM model (e.g., meta/llama-3.1-405b-instruct)"
        if ($modelToUse) { 
            # Critical for NIM: Prevents 404 errors on internal tool calls
            $localSettings.env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = $modelToUse
            # Adds the model to the /model picker inside Claude Code
            $localSettings.env["ANTHROPIC_CUSTOM_MODEL_OPTION"] = $modelToUse
        }
    }
    Default {
        # Anthropic
        $localSettings.env["ANTHROPIC_API_KEY"] = $tokenToUse
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = ""
        $modelToUse = Read-Host "Use custom Anthropic model? (Leave blank for default)"
        if ($modelToUse) { 
            $localSettings.env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = $modelToUse
        }
    }
}

# 3. Plugins Configuration
if ($globalSettings.enabledPlugins -and ($globalSettings.enabledPlugins.PSObject.Properties.Count -gt 0)) {
    Write-Host "`n=== Plugins ===" -ForegroundColor Cyan
    $localSettings.enabledPlugins = @{}
    foreach ($prop in $globalSettings.enabledPlugins.PSObject.Properties) {
        if ($prop.Value -eq $true) {
            $addPlugin = Read-Host "Enable plugin '$($prop.Name)'? (Y/n)"
            if ($addPlugin -eq "" -or $addPlugin.ToLower() -eq 'y') {
                $localSettings.enabledPlugins[$prop.Name] = $true
            }
        }
    }
}

# 4. MCP Configuration
$mcpKeys = @("enabledMcpServers", "mcpServers")
foreach ($key in $mcpKeys) {
    if ($globalSettings.$key -and ($globalSettings.$key.PSObject.Properties.Count -gt 0)) {
        Write-Host "`n=== MCP Servers ===" -ForegroundColor Cyan
        if (-not $localSettings.Contains($key)) { $localSettings[$key] = @{} }
        foreach ($prop in $globalSettings.$key.PSObject.Properties) {
            $addMcp = Read-Host "Enable MCP Server '$($prop.Name)'? (Y/n)"
            if ($addMcp -eq "" -or $addMcp.ToLower() -eq 'y') {
                $localSettings[$key][$prop.Name] = $prop.Value
            }
        }
    }
}

# 5. Inherit remaining settings
if ($globalSettings.effortLevel) {
    $localSettings.effortLevel = $globalSettings.effortLevel
}

# Generate Local Configuration
if (-not (Test-Path $localClaudeDir)) {
    New-Item -ItemType Directory -Force -Path $localClaudeDir | Out-Null
}
$localSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $localConfigPath

Write-Host "`nSuccess! Local project configured at $localConfigPath" -ForegroundColor Green
