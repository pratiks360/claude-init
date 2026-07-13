# cl-config.ps1
param()

$globalClaudeDir = "$env:USERPROFILE\.claude"
$globalConfigPath = Join-Path $globalClaudeDir "settings.json"
$localClaudeDir = Join-Path $PWD ".claude"
$localConfigPath = Join-Path $localClaudeDir "settings.json"

Write-Host "=== Claude Code Local Configurator (cl-config) ===" -ForegroundColor Cyan

# We use an ordered dictionary so the JSON looks clean
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

# Check global config for existing keys
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

# Populate the env block based on the exact schema requirements
switch ($providerChoice) {
    '2' { 
        # OpenRouter
        $localSettings.env["ANTHROPIC_BASE_URL"] = "https://openrouter.ai/api"
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = $tokenToUse
        $localSettings.env["ANTHROPIC_API_KEY"] = ""
        $modelToUse = Read-Host "Enter OpenRouter model (e.g., openai/gpt-4o, leave blank for default)"
        if ($modelToUse) { $localSettings.env["ANTHROPIC_MODEL"] = $modelToUse }
    }
    '3' {
        # NVIDIA NIM
        $localSettings.env["ANTHROPIC_BASE_URL"] = "https://integrate.api.nvidia.com/v1"
        $localSettings.env["ANTHROPIC_API_KEY"] = $tokenToUse
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = ""
        $modelToUse = Read-Host "Enter NVIDIA NIM model (e.g., meta/llama-3.1-405b-instruct, leave blank for default)"
        if ($modelToUse) { $localSettings.env["ANTHROPIC_MODEL"] = $modelToUse }
    }
    Default {
        # Anthropic
        $localSettings.env["ANTHROPIC_API_KEY"] = $tokenToUse
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = ""
        $modelToUse = Read-Host "Use custom Anthropic model? (Leave blank for default)"
        if ($modelToUse) { $localSettings.env["ANTHROPIC_MODEL"] = $modelToUse }
    }
}

# 3. Plugins Configuration (Interactive)
if ($globalSettings.enabledPlugins -and ($globalSettings.enabledPlugins.PSObject.Properties.Count -gt 0)) {
    Write-Host "`n=== Plugins ===" -ForegroundColor Cyan
    Write-Host "Found plugins in global config. Select which to enable in this project:"
    
    $localSettings.enabledPlugins = @{}
    
    foreach ($prop in $globalSettings.enabledPlugins.PSObject.Properties) {
        $pluginName = $prop.Name
        $isGlobalEnabled = $prop.Value
        
        if ($isGlobalEnabled -eq $true) {
            $addPlugin = Read-Host "Enable plugin '$pluginName'? (Y/n)"
            # Default to yes if they just press Enter
            if ($addPlugin -eq "" -or $addPlugin.ToLower() -eq 'y') {
                $localSettings.enabledPlugins[$pluginName] = $true
            }
        }
    }
}

# 4. MCP Configuration (Interactive)
# Check for MCP servers under common keys
$mcpKeys = @("enabledMcpServers", "mcpServers")
foreach ($key in $mcpKeys) {
    if ($globalSettings.$key -and ($globalSettings.$key.PSObject.Properties.Count -gt 0)) {
        Write-Host "`n=== MCP Servers ===" -ForegroundColor Cyan
        Write-Host "Found MCP servers in global config. Select which to enable:"
        
        if (-not $localSettings.Contains($key)) { $localSettings[$key] = @{} }
        
        foreach ($prop in $globalSettings.$key.PSObject.Properties) {
            $mcpName = $prop.Name
            $mcpValue = $prop.Value
            
            $addMcp = Read-Host "Enable MCP Server '$mcpName'? (Y/n)"
            if ($addMcp -eq "" -or $addMcp.ToLower() -eq 'y') {
                $localSettings[$key][$mcpName] = $mcpValue
            }
        }
    }
}

# 5. Inherit remaining generic settings like effortLevel
if ($globalSettings.effortLevel) {
    $localSettings.effortLevel = $globalSettings.effortLevel
}

# Generate Local Configuration
if (-not (Test-Path $localClaudeDir)) {
    New-Item -ItemType Directory -Force -Path $localClaudeDir | Out-Null
}

$localSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $localConfigPath

Write-Host "`nSuccess! Local project configured at $localConfigPath" -ForegroundColor Green
