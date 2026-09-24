#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/app"

# ── Detecta WSL ────────────────────────────────────────────────────────────────
IS_WSL=false
grep -qEi "(microsoft|wsl)" /proc/version 2>/dev/null && IS_WSL=true

# ── config.txt ─────────────────────────────────────────────────────────────────
if [ ! -f "config.txt" ]; then
    echo "config.txt nao encontrado. Copiando config-padrao.txt..."
    cp config-padrao.txt config.txt
fi

PORT=$(grep "^PORT=" config.txt | cut -d'=' -f2 | tr -d '[:space:]')
PORT=${PORT:-3333}

# ── Dependências ───────────────────────────────────────────────────────────────
if [ ! -d "node_modules" ]; then
    echo "Instalando dependencias..."
    npm install
fi

# ── Encerra processo anterior na porta ────────────────────────────────────────
OLD_PID=$(lsof -ti tcp:"$PORT" 2>/dev/null)
if [ -n "$OLD_PID" ]; then
    echo "Encerrando processo anterior na porta $PORT (PID $OLD_PID)..."
    kill -9 "$OLD_PID" 2>/dev/null
    sleep 1
fi

# ── Inicia proxy ───────────────────────────────────────────────────────────────
echo "Iniciando Mock Manager na porta $PORT..."
nohup node proxy.js > proxy.log 2>&1 &
echo $! > proxy.pid
sleep 2

# ── Abre browser ──────────────────────────────────────────────────────────────
URL="http://localhost:$PORT"

if [ "$IS_WSL" = true ]; then
    # No WSL, abre no browser do Windows
    cmd.exe /c start "" "$URL" 2>/dev/null \
    || powershell.exe -Command "Start-Process '$URL'" 2>/dev/null \
    || echo "Abra manualmente: $URL"
else
    # Linux nativo
    xdg-open "$URL" 2>/dev/null \
    || open "$URL" 2>/dev/null \
    || echo "Abra manualmente: $URL"
fi

echo ""
echo "Mock Manager rodando em: $URL"
echo "Para encerrar: ./stop.sh"
