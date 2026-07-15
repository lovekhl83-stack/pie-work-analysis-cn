@echo off
chcp 65001 >nul 2>&1
title PIE ST 누적 서버

if not exist "%~dp0PIE_ST_server.ps1" (
    echo.
    echo  [오류] PIE_ST_server.ps1 파일을 찾을 수 없습니다.
    echo.
    pause
    exit /b 1
)

echo.
echo  PIE ST 누적 서버를 실행합니다...
echo  다른 PC들이 이 PC의 주소를 등록하면 부품 ST를 함께 누적할 수 있습니다.
echo  이 창을 닫으면 서버가 종료됩니다.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0PIE_ST_server.ps1"
