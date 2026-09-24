@echo off
cd /d "%~dp0app"

if not exist "config.txt" (
    echo config.txt nao encontrado. Copiando config-padrao.txt...
    copy config-padrao.txt config.txt
)

for /f "tokens=1,2 delims==" %%a in (config.txt) do (
    if "%%a"=="PORT" set PORT=%%b
)
if "%PORT%"=="" set PORT=3333

if not exist "node_modules" (
    echo Instalando dependencias...
    npm install
)

echo Encerrando processo anterior na porta %PORT% (se houver)...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%PORT% "') do taskkill /f /pid %%a >nul 2>&1

echo Iniciando Mock Manager na porta %PORT%...
start /b node proxy.js > proxy.log 2>&1

timeout /t 2 /nobreak > nul

echo Abrindo http://localhost:%PORT% ...
start "" "http://localhost:%PORT%"

echo.
echo Mock Manager rodando em: http://localhost:%PORT%
echo Para encerrar, execute stop.bat
