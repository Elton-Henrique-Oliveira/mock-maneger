@echo off
REM Uso direto (avançado): encerra o proxy.
REM Para uso normal, execute stop.bat na raiz do projeto.
cd /d "%~dp0"

for /f "tokens=1,2 delims==" %%a in (config.txt) do (
    if "%%a"=="PORT" set PORT=%%b
)
if "%PORT%"=="" set PORT=3333

echo Encerrando proxy na porta %PORT%...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%PORT% "') do taskkill /f /pid %%a >nul 2>&1
echo Encerrado.
