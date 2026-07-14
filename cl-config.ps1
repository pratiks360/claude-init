# cl-config.ps1
param()

$globalClaudeDir = "$env:USERPROFILE\.claude"
$globalConfigPath = Join-Path $globalClaudeDir "settings.json"
$localClaudeDir = Join-Path $PWD ".claude"
$localConfigPath = Join-Path $localClaudeDir "settings.local.json"

# Find where this CLI is installed so we can locate the proxy script
$installDir = "$env:USERPROFILE\.cl-config-cli"
$proxyScriptPath = Join-Path $installDir "universal-proxy.js"

Write-Host "=== Claude Code Local Configurator (cl-config) ===" -ForegroundColor Cyan

$localSettings = [ordered]@{
    env = @{}
}

# 1. Load Global Settings
$globalSettings = $null
if (Test-Path $globalConfigPath) {
    try {
        $globalSettings = Get-Content $globalConfigPath -Raw | ConvertFrom-Json
    } catch {}
}

# 2. Provider Selection
Write-Host "`nSelect LLM Provider for this project:"
Write-Host "1. Anthropic (Default)"
Write-Host "2. OpenRouter"
Write-Host "3. NVIDIA NIM"
Write-Host "4. Dahl"
Write-Host "5. Puter"
$providerChoice = Read-Host "Enter choice (1-5)"

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

# Function to spawn the proxy for custom providers
function Start-ProxyWindow($ProviderName) {
    if (-not (Get-Command "node" -ErrorAction SilentlyContinue)) {
        Write-Host "`n[ERROR] Node.js is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Dahl and Puter require Node.js to run the local translation proxy." -ForegroundColor Yellow
        exit
    }
    
    Write-Host "`nSpawning proxy server for $ProviderName..." -ForegroundColor Magenta
    
    # Opens a new CMD window, sets the title, warns the user, and starts node. 
    # /k keeps the window open so they can see logs.
    $cmdArgs = "/k title Claude Code Proxy - DO NOT CLOSE & echo ================================================== & echo DO NOT CLOSE THIS WINDOW & echo Claude Code is using this proxy to talk to $ProviderName & echo ================================================== & node `"$proxyScriptPath`""
    Start-Process cmd -ArgumentList $cmdArgs
}

# Populate the env block
switch ($providerChoice) {
    '2' { 
        $localSettings.env["ANTHROPIC_BASE_URL"] = "https://openrouter.ai/api"
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = $tokenToUse
        $localSettings.env["ANTHROPIC_API_KEY"] = ""
        $modelToUse = Read-Host "Enter OpenRouter model (e.g., openai/gpt-oss-120b:free)"
        if ($modelToUse) { 
            $localSettings.env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = $modelToUse
            $localSettings.env["CLAUDE_CODE_SUBAGENT_MODEL"] = $modelToUse
        }
    }
    '3' {
        $localSettings.env["ANTHROPIC_BASE_URL"] = "https://integrate.api.nvidia.com/v1"
        $localSettings.env["ANTHROPIC_API_KEY"] = $tokenToUse
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = ""
        $modelToUse = Read-Host "Enter NVIDIA NIM model (e.g., meta/llama-3.1-405b-instruct)"
        if ($modelToUse) { 
            $localSettings.env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = $modelToUse
            $localSettings.env["CLAUDE_CODE_SUBAGENT_MODEL"] = $modelToUse
        }
    }
    '4' {
        Start-ProxyWindow "Dahl"
        $localSettings.env["ANTHROPIC_BASE_URL"] = "http://127.0.0.1:4000/dahl"
        $localSettings.env["ANTHROPIC_API_KEY"] = $tokenToUse
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = ""
        $modelToUse = Read-Host "Enter Dahl model (Leave blank for MiniMaxAI/MiniMax-M2.7)"
        if (-not $modelToUse) { $modelToUse = "MiniMaxAI/MiniMax-M2.7" }
        
        $localSettings.env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = $modelToUse
        $localSettings.env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = $modelToUse
        $localSettings.env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = $modelToUse
        $localSettings.env["CLAUDE_CODE_SUBAGENT_MODEL"] = $modelToUse
    }
    '5' {
        Start-ProxyWindow "Puter"
        $localSettings.env["ANTHROPIC_BASE_URL"] = "http://127.0.0.1:4000/puter"
        $localSettings.env["ANTHROPIC_API_KEY"] = $tokenToUse
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = ""
        $modelToUse = Read-Host "Enter Puter model (Leave blank for deepseek-chat)"
        if (-not $modelToUse) { $modelToUse = "deepseek-chat" }

        $localSettings.env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = $modelToUse
        $localSettings.env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = $modelToUse
        $localSettings.env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = $modelToUse
        $localSettings.env["CLAUDE_CODE_SUBAGENT_MODEL"] = $modelToUse
    }
    Default {
        $localSettings.env["ANTHROPIC_API_KEY"] = $tokenToUse
        $localSettings.env["ANTHROPIC_AUTH_TOKEN"] = ""
        $modelToUse = Read-Host "Use custom Anthropic model? (Leave blank for default)"
        if ($modelToUse) { 
            $localSettings.env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = $modelToUse
            $localSettings.env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = $modelToUse
            $localSettings.env["CLAUDE_CODE_SUBAGENT_MODEL"] = $modelToUse
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
if ($providerChoice -eq '4' -or $providerChoice -eq '5') {
    Write-Host "You can now run 'claude' in this terminal. (Keep the proxy window open in the background)." -ForegroundColor Yellow
}
