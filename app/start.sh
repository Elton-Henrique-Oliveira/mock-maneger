#!/bin/bash
# Uso direto (avançado): sobe apenas o proxy, sem abrir browser.
# Para uso normal, execute ./run.sh na raiz do projeto.
cd "$(dirname "$0")"

if [ ! -f "config.txt" ]; then
    cp config-padrao.txt config.txt
fi

PORT=$(grep "^PORT=" config.txt | cut -d'=' -f2 | tr -d '[:space:]')
PORT=${PORT:-3333}

if [ ! -d "node_modules" ]; then
    npm install
fi

OLD_PID=$(lsof -ti tcp:"$PORT" 2>/dev/null)
if [ -n "$OLD_PID" ]; then
    kill -9 "$OLD_PID" 2>/dev/null
    sleep 1
fi

nohup node proxy.js > proxy.log 2>&1 &
echo $! > proxy.pid
echo "Proxy iniciado na porta $PORT (PID $(cat proxy.pid))"
echo "Acesse: http://localhost:$PORT"
