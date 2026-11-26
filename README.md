# Windows 11 MCP Agent Config Scanner

Portable read-only scanner for auditing local MCP agent configurations on Windows 11.

## Quick Start & SmartScreen Unblock
1. Extract the release archive to a local folder (avoiding protected system paths if running interactive scripts).
2. If Windows blocks scripts or `.bat` launchers from the web, right-click the file -> **Properties** -> check **Unblock** -> **OK**, or run in PowerShell:

    Unblock-File -Path .\*.ps1, .\*.bat -ErrorAction SilentlyContinue

3. Run `RUN_MCP_SCANNER.bat` (or `Scan-MCP-Agent-Configs.ps1` in PowerShell).

## Related Gumroad Listings
- **MCP Config Health Scanner (Free):** https://gumroad.com/l/ofxozx
- **MCP Config, Profile & Backup Manager ($19):** https://gumroad.com/l/azwibq
- **Local AI & Agent Builder Suite - 3-in-1 Bundle ($29):** https://gumroad.com/l/pfsgkz
