# Mock Manager

Interface visual para gerenciar mocks de APIs e eventos Kafka armazenados no MongoDB.

## Pré-requisitos

- [Node.js](https://nodejs.org/) 18+
- Acesso a uma instância MongoDB (local ou Atlas)

---

## Como rodar

### Windows

Dê dois cliques em `run.bat` — ou execute no terminal:

```bat
run.bat
```

O browser abre automaticamente em `http://localhost:3333`.

Para encerrar:

```bat
stop.bat
```

---

### Linux

```bash
chmod +x run.sh stop.sh
./run.sh
```

Para encerrar:

```bash
./stop.sh
```

---

### WSL (Windows Subsystem for Linux)

```bash
chmod +x run.sh stop.sh
./run.sh
```

O script detecta WSL automaticamente e abre `http://localhost:3333` no browser do Windows.

Para encerrar:

```bash
./stop.sh
```

> **Problema de DNS no WSL?** Se o browser não conectar via `localhost`, veja a seção [Problema de DNS no WSL](#problema-de-dns-no-wsl) abaixo.

---

### Via npm

```bash
cd app
npm install
npm start
```

Acesse `http://localhost:3333` no browser.

---

## Estrutura do projeto

```
mock-manager/
├── run.bat       ← Iniciar no Windows  (duplo clique)
├── run.sh        ← Iniciar no Linux/WSL
├── stop.bat      ← Encerrar no Windows
├── stop.sh       ← Encerrar no Linux/WSL
├── README.md
└── app/          ← Código fonte (não precisa mexer aqui)
    ├── proxy.js
    ├── index.html
    ├── databases.json
    ├── config-padrao.txt
    ├── config.txt        (gerado automaticamente, ignorado pelo git)
    ├── package.json
    └── ...
```

---

## Configuração

Na primeira execução, `app/config.txt` é criado automaticamente a partir de `app/config-padrao.txt`.

Para ajustar, edite `app/config.txt`:

```
PORT=3333
ENDPOINTS_CATALOG_URL=
ALLOW_DELETE=true
```

| Chave | Descrição | Padrão |
|---|---|---|
| `PORT` | Porta do servidor | `3333` |
| `ENDPOINTS_CATALOG_URL` | URL do catálogo de endpoints (opcional) | vazio |
| `ALLOW_DELETE` | Habilita botão de deletar documentos | `true` |

As configurações também podem ser editadas pela interface em ⚙️ **Configurações**.

> Alterações de porta só têm efeito após reiniciar (`stop` + `run`).

---

## Configurando os Databases

Edite `app/databases.json` ou use ⚙️ **Configurações → Databases** na interface:

```json
[
  {
    "name": "meu-servico",
    "collections": [
      "mocks",
      "kafka_messages_mock_inbound",
      "kafka_messages_mock"
    ]
  },
  {
    "name": "outro-servico",
    "collections": ["mocks"]
  }
]
```

---

## Problema de DNS no WSL

Quando o proxy roda no WSL e o browser está no Windows, `localhost` no browser aponta para o Windows — não para o WSL.

O `run.sh` já resolve isso automaticamente abrindo `http://localhost:3333` via `cmd.exe` do Windows. Na maioria dos casos o WSL2 faz bridge de `localhost` automaticamente.

Se mesmo assim não conectar:

1. Descubra o IP do WSL:
   ```bash
   hostname -I
   # ex: 172.26.144.10
   ```

2. Acesse no browser Windows: `http://172.26.144.10:3333`

3. Para fixar: adicione ao `C:\Windows\System32\drivers\etc\hosts` (como Administrador):
   ```
   172.26.144.10  wsl.local
   ```
   E acesse `http://wsl.local:3333`.

> O IP do WSL pode mudar a cada reinicialização do Windows.

---

## Conectando ao MongoDB

Na tela de login, preencha:

- **MongoDB URI** — ex: `mongodb+srv://user:pass@host/db` ou `mongodb://localhost:27017`
- **Database** — selecione na lista ou clique em "Digitar manualmente"
- **Collection** — collection que deseja gerenciar

---

## Collections especiais

### `mocks` — API Mocks

Três tipos de mock:

#### 🌐 WebClient Genérico
`_id` = `MÉTODO:/caminho`. Fallback para chamadas de saída sem mock por usuário.

```json
{
  "_id": "GET:/v1/products/stock-status",
  "enabled": true,
  "payload": { "available": true, "quantity": 42 },
  "externalMockProperties": null
}
```

#### 👤 WebClient por Usuário
Retorna payload diferente por identificador de recurso.

```json
{
  "_id": "mock-pricing-order-001",
  "enabled": true,
  "payload": { "orderId": "order-001", "finalPrice": 89.50 },
  "externalMockProperties": {
    "endpointId": "GET:/v1/orders/pricing",
    "allowedUsers": ["order-001"]
  }
}
```

#### 🔖 X-MOCK-ID
Intercepta requisições recebidas pelo serviço via header `X-MOCK-ID`.

```bash
curl -X POST http://localhost:8080/checkout \
  -H "X-MOCK-ID: checkout-mock" \
  -d '{"orderId": "order-001"}'
```

---

### `kafka_messages_mock_inbound` — Eventos Kafka de entrada

Documentos consumidos pelo serviço como mensagens Kafka simuladas.

```json
{
  "topic": "order-created",
  "key": "order-001",
  "payload": { "orderId": "order-001", "total": 99.90 },
  "processed": false,
  "createdAt": "2024-01-15T10:00:00.000Z"
}
```

### `kafka_messages_mock` — Mensagens Kafka de saída

Somente leitura. Mensagens publicadas pelo serviço durante execução local.

---

## Prioridade dos mocks

1. **Por Usuário** — se o identificador estiver em `allowedUsers`
2. **WebClient Genérico** — fallback (o `_id` deve ser idêntico ao `endpointId` dos mocks por usuário)

A interface exibe avisos visuais nos cards quando detecta conflito.
