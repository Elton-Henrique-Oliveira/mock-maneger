@echo off
cd /d "%~dp0app"

for /f "tokens=1,2 delims==" %%a in (config.txt) do (
    if "%%a"=="PORT" set PORT=%%b
)
if "%PORT%"=="" set PORT=3333

echo Encerrando Mock Manager na porta %PORT%...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%PORT% "') do taskkill /f /pid %%a >nul 2>&1
echo Encerrado.
