@echo off
chcp 65001 >nul 2>&1
title PIE - USB Package Builder
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0PIE_USB_묶기.ps1"
