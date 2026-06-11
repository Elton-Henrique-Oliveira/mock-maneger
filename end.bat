@echo off
for /f "tokens=1,2 delims==" %%a in (config.txt) do (
    if "%%a"=="PORT" set PORT=%%b
)
echo Encerrando Mock Manager Proxy na porta %PORT%...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%PORT%"') do taskkill /f /pid %%a >nul 2>&1
echo Proxy encerrado.
