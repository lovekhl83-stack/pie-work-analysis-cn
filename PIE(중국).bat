@echo off
chcp 65001 >nul 2>&1
title PIE(중국) - Powernet Industrial Engineering (오프라인)

if not exist "%~dp0PIE.html" (
    echo.
    echo  [오류] PIE.html 파일을 찾을 수 없습니다.
    echo  PIE(중국).bat와 PIE.html이 같은 폴더에 있어야 합니다.
    echo.
    pause
    exit /b 1
)

echo.
echo  PIE(중국) 작업분석 프로그램(오프라인)을 실행합니다...
echo  Pose 비교 기능(MediaPipe)이 로컬 파일에서 정상 동작하도록
echo  로컬 서버를 통해 실행합니다. 인터넷 연결이 필요 없습니다.
echo  이 창을 닫으면 프로그램이 종료됩니다.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0PIE_local_server.ps1"
