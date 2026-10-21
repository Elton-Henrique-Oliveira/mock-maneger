#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/app"

PORT=$(grep "^PORT=" config.txt 2>/dev/null | cut -d'=' -f2 | tr -d '[:space:]')
PORT=${PORT:-3333}

echo "Encerrando Mock Manager na porta $PORT..."

# Tenta pelo PID salvo
if [ -f "proxy.pid" ]; then
    SAVED_PID=$(cat proxy.pid)
    if kill -0 "$SAVED_PID" 2>/dev/null; then
        kill "$SAVED_PID" 2>/dev/null
        echo "Encerrado (PID $SAVED_PID)."
        rm -f proxy.pid
        exit 0
    fi
    rm -f proxy.pid
fi

# Fallback: encontra pela porta
PID=$(lsof -ti tcp:"$PORT" 2>/dev/null)
if [ -n "$PID" ]; then
    kill -9 "$PID" 2>/dev/null
    echo "Encerrado (PID $PID)."
else
    echo "Nenhum processo encontrado na porta $PORT."
fi
