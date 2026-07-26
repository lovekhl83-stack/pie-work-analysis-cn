@echo off
if not exist "%~dp0PIE_uninstall.ps1" (
    echo [ERROR] PIE_uninstall.ps1 not found in this folder.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PIE_uninstall.ps1"
