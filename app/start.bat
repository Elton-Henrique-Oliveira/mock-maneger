@echo off
REM Uso direto (avançado): sobe apenas o proxy, sem abrir browser.
REM Para uso normal, execute run.bat na raiz do projeto.
cd /d "%~dp0"

if not exist "config.txt" copy config-padrao.txt config.txt

for /f "tokens=1,2 delims==" %%a in (config.txt) do (
    if "%%a"=="PORT" set PORT=%%b
)
if "%PORT%"=="" set PORT=3333

if not exist "node_modules" npm install

for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%PORT% "') do taskkill /f /pid %%a >nul 2>&1

start /b node proxy.js > proxy.log 2>&1
echo Proxy iniciado na porta %PORT%
echo Acesse: http://localhost:%PORT%
