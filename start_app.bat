@echo off
cd /d D:\dailylifeapp\build\web
start /b python -m http.server 8080
start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" "http://localhost:8080"