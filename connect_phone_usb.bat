@echo off
title Product Management - Mobile Connection Helper
echo =======================================================
echo   Product Management System - Mobile Connection Info
echo =======================================================
echo.

:: Get current Wi-Fi IP address
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias '*Wi-Fi*' -ErrorAction SilentlyContinue).IPAddress"`) do set WIFI_IP=%%i

if defined WIFI_IP (
    echo [Wi-Fi Connection]
    echo   Your Computer IP: %WIFI_IP%
    echo   Mobile App URL  : http://%WIFI_IP%:8000/api
    echo.
)

:: Setup USB ADB reverse if phone is connected
set ADB=adb
where adb >nul 2>nul
if %errorlevel% neq 0 (
    if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
        set ADB="%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
    )
)

echo [USB Cable Connection]
%ADB% reverse tcp:8000 tcp:8000 >nul 2>&1
if %errorlevel% equ 0 (
    echo   Status         : USB Reverse Forwarding ACTIVE!
    echo   Mobile App URL : http://127.0.0.1:8000/api
) else (
    echo   Status         : USB Phone not detected.
    echo   Tip            : Plug USB cable and turn on USB Debugging.
)

echo.
echo =======================================================
echo   IP Advice:
echo   - USB Cable (127.0.0.1) NEVER changes!
echo   - Wi-Fi IP may change if router restarts.
echo =======================================================
echo.
pause
