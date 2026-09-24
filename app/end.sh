#!/bin/bash
# Uso direto (avançado): encerra o proxy.
# Para uso normal, execute ./stop.sh na raiz do projeto.
cd "$(dirname "$0")"

PORT=$(grep "^PORT=" config.txt 2>/dev/null | cut -d'=' -f2 | tr -d '[:space:]')
PORT=${PORT:-3333}

echo "Encerrando proxy na porta $PORT..."

if [ -f "proxy.pid" ]; then
    SAVED_PID=$(cat proxy.pid)
    if kill -0 "$SAVED_PID" 2>/dev/null; then
        kill "$SAVED_PID" && echo "Encerrado (PID $SAVED_PID)." && rm -f proxy.pid && exit 0
    fi
    rm -f proxy.pid
fi

PID=$(lsof -ti tcp:"$PORT" 2>/dev/null)
if [ -n "$PID" ]; then
    kill -9 "$PID" && echo "Encerrado (PID $PID)."
else
    echo "Nenhum processo encontrado na porta $PORT."
fi
