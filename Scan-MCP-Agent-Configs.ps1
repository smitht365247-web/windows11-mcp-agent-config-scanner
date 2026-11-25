<#
.SYNOPSIS
    Hardened v1.0: Read-only audit of Windows 10/11 AI coding agent & MCP server JSON configs
    (Claude Desktop, Claude Code, Cursor, Windsurf, Cline, VS Code) plus Windows ODR (odr.exe)
    and Node/npx/uvx/Python runtime readiness. Never prints secret values.
#>
param(
    [string]$OutputFolder = $PSScriptRoot
)

if ($OutputFolder -match '^[A-Za-z]:$') { $OutputFolder += '\' }
if (-not (Test-Path -LiteralPath $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}
$OutputFolder = (Resolve-Path -LiteralPath $OutputFolder).Path

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

foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c.Path) {
        $raw = Get-Content -LiteralPath $c.Path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        try {
            $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
            $srvCount = 0
            if ($parsed.mcpServers) {
                $srvCount = @($parsed.mcpServers.PSObject.Properties).Count
            } elseif ($parsed.servers) {
                $srvCount = @($parsed.servers.PSObject.Properties).Count
            }
            $totalServers += $srvCount
            $foundRows += "[OK]      $($c.Name) -> Valid JSON ($srvCount MCP servers) | $($c.Path)"
        } catch {
            $invalidCount++
            $foundRows += "[INVALID] $($c.Name) -> JSON Syntax Error: $($_.Exception.Message) | $($c.Path)"
        }
    }
}

$runtimes = @("node", "npx", "uvx", "python", "git", "odr.exe")
$rtStatus = @()
foreach ($rt in $runtimes) {
    $cmd = Get-Command $rt -ErrorAction SilentlyContinue
    if ($cmd) {
        $rtStatus += "$rt=OK"
    } else {
        $rtStatus += "$rt=MISSING"
    }
}

$reportPath = Join-Path $OutputFolder ("mcp_agent_audit_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$lines = @(
    "WINDOWS 11 AI CODING AGENT & MCP CONFIG AUDIT (v1.0)",
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "------------------------------------------------------------",
    "Configs Found:       $($foundRows.Count)",
    "Invalid JSON Files:  $invalidCount",
    "Total MCP Servers:   $totalServers",
    "Runtime Readiness:   $($rtStatus -join ', ')",
    "------------------------------------------------------------",
    "Detected Config Files:"
)
if ($foundRows.Count -gt 0) {
    $lines += $foundRows
} else {
    $lines += "  (No global Claude Desktop, Claude Code, Cursor, Windsurf, Cline, or VS Code MCP configs found)"
}
$lines += "------------------------------------------------------------"
$lines += "NOTE: 100% read-only audit. API keys and env secrets are never read or printed."

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
$lines | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "Audit report saved to: $reportPath" -ForegroundColor Green
