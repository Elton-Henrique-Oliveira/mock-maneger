#!/bin/bash
cd "$(dirname "$0")"

if [ ! -f "config.txt" ]; then
    echo "config.txt nao encontrado. Copiando config-padrao.txt..."
    cp config-padrao.txt config.txt
fi

PORT=$(grep "^PORT=" config.txt | cut -d'=' -f2)

if [ ! -d "node_modules" ]; then
    echo "Instalando dependencias..."
    npm install
fi

echo "Iniciando proxy na porta $PORT..."
nohup node proxy.js > proxy.log 2>&1 &

sleep 4

echo "Abrindo Mock Manager..."
xdg-open index.html 2>/dev/null || open index.html 2>/dev/null || echo "Abra index.html manualmente no navegador."
