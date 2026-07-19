@echo off
chcp 65001 >nul
echo ==========================================
echo  DailyLifeApp launcher
echo ==========================================

REM 1. Ensure Python server is running on 8080
netstat -ano | findstr :8080 | findstr LISTENING >nul
if %errorlevel%==0 (
  echo [OK] Server already running on 8080
) else (
  echo [Starting] Python server...
  cscript //NoLogo "D:\dailylifeapp\start_server.vbs"
)

REM 2. Open in Edge with a cache-busting query string. The timestamp avoids
REM    Service Worker reusing a stale build. No need to wait — Edge loads
REM    asynchronously after this script exits.
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set TS=%%T
echo [Open] http://localhost:8080/?nocache=%TS%
start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --new-window "http://localhost:8080/?nocache=%TS%"

echo Done!