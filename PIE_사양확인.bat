@echo off
chcp 65001 >nul 2>&1
title PIE - System Check
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0PIE_사양확인.ps1"
