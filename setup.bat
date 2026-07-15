@echo off
echo.
echo  ============================================
echo   PIE - Powernet Industrial Engineering
echo   Work Analysis System  v1.0
echo  ============================================
echo.

:: Check source file exists
if not exist "%~dp0PIE.html" (
    echo  [ERROR] PIE.html not found.
    echo  Make sure PIE.html is in the same folder as this setup.bat
    echo.
    pause
    exit /b 1
)

:: Get the real Desktop path (handles Korean Windows, OneDrive, etc.)
for /f "usebackq delims=" %%a in (`powershell -noprofile -command "[Environment]::GetFolderPath('Desktop')"`) do set "DESK=%%a"
if "%DESK%"=="" set "DESK=%USERPROFILE%\Desktop"

:: Copy PIE.html directly to Desktop
echo  Copying to Desktop...
copy /Y "%~dp0PIE.html" "%DESK%\PIE.html" >nul
if errorlevel 1 (
    echo.
    echo  [ERROR] Could not copy file to Desktop.
    echo  Please try: Right-click setup.bat ^> Run as administrator
    echo.
    pause
    exit /b 1
)

echo  [OK] PIE.html installed to: %DESK%
echo.
echo  Opening PIE...
start "" "%DESK%\PIE.html"

echo.
echo  Setup complete!
echo  - Double-click PIE.html on your Desktop to launch
echo  - A license key is required on first launch
echo  - Contact: lovekhl83@gmail.com
echo.
pause
