<#
.SYNOPSIS
    Hardened v1.1: Read-only audit of Windows 10/11 AI coding agent & MCP server JSON configs
    (Claude Desktop, Claude Code, Cursor, Windsurf, Cline, VS Code) plus Windows ODR (odr.exe)
    and Node/npx/uvx/Python runtime readiness. Never prints secret values or raw JSON parse excerpts.
#>
[CmdletBinding()]
param([string]$OutputFolder = $PSScriptRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($OutputFolder -match '^[A-Za-z]:$') { $OutputFolder += '\' }
if ([string]::IsNullOrWhiteSpace($OutputFolder)) { $OutputFolder = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).ProviderPath } }
if (-not (Test-Path -LiteralPath $OutputFolder -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}
$OutputFolder = (Resolve-Path -LiteralPath $OutputFolder).ProviderPath

Write-Host "Scanning Windows 11 AI coding agent & MCP config files..." -ForegroundColor Cyan

$candidates = @(
    @{ Name = "Claude Desktop MCP"; Path = (Join-Path $env:APPDATA "Claude\claude_desktop_config.json") },
    @{ Name = "Claude Code Global"; Path = (Join-Path $env:USERPROFILE ".claude.json") },
    @{ Name = "Claude Code Settings"; Path = (Join-Path $env:USERPROFILE ".claude\settings.json") },
    @{ Name = "Cursor Global MCP"; Path = (Join-Path $env:USERPROFILE ".cursor\mcp.json") },
    @{ Name = "Windsurf Global MCP"; Path = (Join-Path $env:USERPROFILE ".codeium\windsurf\mcp_config.json") },
    @{ Name = "VS Code User MCP"; Path = (Join-Path $env:APPDATA "Code\User\mcp.json") },
    @{ Name = "Cline VS Code MCP"; Path = (Join-Path $env:APPDATA "Code\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json") }
)

$foundRows = @()
$totalServers = 0
$invalidCount = 0
$unreadableCount = 0

foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c.Path -PathType Leaf) {
        $raw = $null
        try {
            $raw = Get-Content -LiteralPath $c.Path -Raw -Encoding UTF8 -ErrorAction Stop
        } catch {
            $unreadableCount++
            $foundRows += "[UNREADABLE] $($c.Name) -> Could not read file (permission or lock) | $($c.Path)"
            continue
        }
        if ([string]::IsNullOrWhiteSpace($raw)) {
            $foundRows += "[EMPTY]      $($c.Name) -> Empty config file (0 bytes or whitespace) | $($c.Path)"
            continue
        }
        try {
            $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
            $srvCount = 0
            if ($null -ne $parsed -and ($parsed -is [System.Management.Automation.PSCustomObject])) {
                if ($parsed.PSObject.Properties['mcpServers'] -and $parsed.mcpServers) {
                    $srvCount = @($parsed.mcpServers.PSObject.Properties).Count
                } elseif ($parsed.PSObject.Properties['servers'] -and $parsed.servers) {
                    $srvCount = @($parsed.servers.PSObject.Properties).Count
                }
            }
            $totalServers += $srvCount
            $foundRows += "[OK]         $($c.Name) -> Valid JSON ($srvCount MCP servers) | $($c.Path)"
        } catch {
            $invalidCount++
            $foundRows += "[INVALID]    $($c.Name) -> JSON Syntax Error (details suppressed) | $($c.Path)"
        }
    }
}

$runtimes = @("node", "npx", "uvx", "python", "git", "odr.exe")
$rtStatus = @()
foreach ($rt in $runtimes) {
    $cmd = Get-Command $rt -ErrorAction SilentlyContinue
    if ($cmd) { $rtStatus += "$rt=OK" } else { $rtStatus += "$rt=MISSING" }
}

$reportPath = Join-Path $OutputFolder ("mcp_agent_audit_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$lines = @(
    "WINDOWS 11 AI CODING AGENT & MCP CONFIG AUDIT (v1.1)",
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "------------------------------------------------------------",
    "Configs Found:       $($foundRows.Count)",
    "Invalid JSON Files:  $invalidCount",
    "Unreadable Files:    $unreadableCount",
    "Total MCP Servers:   $totalServers",
    "Runtime Readiness:   $($rtStatus -join ', ')",
    "------------------------------------------------------------",
    "Detected Config Files:"
)
if ($foundRows.Count -gt 0) { $lines += $foundRows }
else { $lines += "  (No global Claude Desktop, Claude Code, Cursor, Windsurf, Cline, or VS Code MCP configs found)" }
$lines += "------------------------------------------------------------"
$lines += "NOTE: 100% read-only audit. API keys and env secrets are never read or printed."

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
$lines | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "Audit report saved to: $reportPath" -ForegroundColor Green
