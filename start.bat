@echo off
cd /d "%~dp0"

if not exist "config.txt" (
    echo config.txt nao encontrado. Copiando config-padrao.txt...
    copy config-padrao.txt config.txt
)

for /f "tokens=1,2 delims==" %%a in (config.txt) do (
    if "%%a"=="PORT" set PORT=%%b
)

if not exist "node_modules" (
    echo Instalando dependencias...
    npm install
)

echo Iniciando proxy na porta %PORT%...
start /b node proxy.js > proxy.log 2>&1

timeout /t 4 /nobreak > nul

echo Abrindo Mock Manager...
start "" index.html
