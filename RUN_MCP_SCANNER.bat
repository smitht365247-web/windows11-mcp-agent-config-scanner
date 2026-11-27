@echo off
setlocal DisableDelayedExpansion
title Windows 11 AI Coding Agent & MCP Config Health Scanner (v1.1)

:START
cls
echo ====================================================================
echo   WINDOWS 11 AI CODING AGENT ^& MCP CONFIG HEALTH SCANNER (v1.1)
echo   (Portable Windows Toolkit ^| Read-Only Audit ^| Zero Secret Leaks)
echo ====================================================================
echo.
set "outDir=%~dp0"
if "%outDir:~-1%"=="\" set "outDir=%outDir:~0,-1%"
set "customOut="
set /p "customOut=Save report in this folder? Press Enter for default or paste a folder path: "
if not defined customOut goto :RUN_SCAN
set "customOut=%customOut:"=%"
if "%customOut%"=="" goto :RUN_SCAN
if "%customOut:~-1%"=="\" set "customOut=%customOut:~0,-1%"
set "outDir=%customOut%"

:RUN_SCAN
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Scan-MCP-Agent-Configs.ps1" -OutputFolder "%outDir%"
echo.
pause
goto START