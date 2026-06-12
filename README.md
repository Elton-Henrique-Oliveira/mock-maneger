# Mock Manager

Interface visual para gerenciar mocks de APIs e eventos Kafka armazenados no MongoDB. Roda localmente via um proxy Node.js que intermedia a conexão com o banco — sem expor credenciais no browser.

## Pré-requisitos

- [Node.js](https://nodejs.org/) 18+
- Acesso a uma instância MongoDB (local ou Atlas)

---

## Iniciando

Dê dois cliques em `start.bat` ou execute no terminal:

```bat
start.bat
```

O script vai:
1. Criar o `config.txt` automaticamente a partir do `config-padrao.txt` se ele não existir
2. Instalar as dependências (`npm install`) se `node_modules` não existir
3. Subir o proxy na porta configurada
4. Abrir o `index.html` no navegador padrão

---

## Encerrando

Dê dois cliques em `end.bat` ou execute no terminal:

```bat
end.bat
```

O script encerra o processo do proxy que estiver rodando na porta configurada.

---

## Configuração

O arquivo `config.txt` é ignorado pelo git (não é versionado). Na primeira execução ele é criado automaticamente a partir do `config-padrao.txt`.

Para ajustar as configurações, edite o `config.txt`:

```
PORT=3333
ENDPOINTS_CATALOG_URL=
ALLOW_DELETE=true
```

| Chave                  | Descrição                                                                                 | Padrão |
|------------------------|-------------------------------------------------------------------------------------------|--------|
| `PORT`                 | Porta em que o proxy vai rodar                                                            | `3333` |
| `ENDPOINTS_CATALOG_URL`| URL de uma API que retorna um catálogo de endpoints (opcional, veja seção abaixo)        | vazio  |
| `ALLOW_DELETE`         | Habilita ou desabilita o botão de deletar documentos na interface                        | `true` |

---

## Configurando os Databases

O arquivo `databases.json` define quais databases e collections aparecem no seletor da tela de login.

Edite conforme o seu projeto:

```json
[
  {
    "name": "nome-do-seu-database",
    "collections": [
      "mocks",
      "kafka_messages_mock_inbound",
      "kafka_messages_mock"
    ]
  }
]
```

Você pode adicionar múltiplos databases:

```json
[
  {
    "name": "meu-servico",
    "collections": ["mocks", "kafka_messages_mock_inbound", "kafka_messages_mock"]
  },
  {
    "name": "outro-servico",
    "collections": ["mocks"]
  }
]
```

---

## Conectando

Na tela de login, preencha:

- **MongoDB URI** — a URI de conexão com o banco (ex: `mongodb+srv://user:pass@host/db` ou `mongodb://localhost:27017`)
- **Database** — selecione na lista gerada pelo `databases.json` ou clique em "Digitar manualmente"
- **Collection** — selecione a collection que deseja gerenciar
- **Porta do Proxy** — deve ser a mesma do `config.txt` (padrão: `3333`)

---

## Collections especiais

O Mock Manager tem interfaces dedicadas para três collections. Para outras collections, exibe uma tabela genérica.

### `mocks` — API Mocks

Gerencia mocks de respostas HTTP. Suporta três tipos:

#### 🌐 WebClient Genérico
Intercepta chamadas de saída do serviço para APIs externas via `WebClient`. O `_id` do documento deve ser exatamente `MÉTODO:/caminho` — e deve ser **idêntico** ao `endpointId` usado nos mocks por usuário para o mesmo endpoint:

```json
{
  "_id": "GET:/v1/products/stock-status",
  "description": "Mock status de estoque",
  "enabled": true,
  "payload": {
    "productId": "prod-001",
    "available": true,
    "quantity": 42
  },
  "externalMockProperties": null
}
```

Ative no `application-local.yml` do serviço:
```yaml
mocks:
  webclient:
    enabled: true
```

#### 👤 WebClient por Usuário
Retorna payloads diferentes por identificador de recurso. O `endpointId` é o mesmo padrão `MÉTODO:/caminho` e `allowedUsers` lista os identificadores que devem receber esse mock:

```json
{
  "_id": "mock-pricing-order-001",
  "description": "Mock precificação para pedido order-001",
  "enabled": true,
  "payload": {
    "orderId": "order-001",
    "discount": 10.5,
    "finalPrice": 89.50
  },
  "externalMockProperties": {
    "endpointId": "GET:/v1/orders/pricing",
    "allowedUsers": ["order-001", "order-002"]
  }
}
```

#### 🔖 X-MOCK-ID
Intercepta requisições **recebidas** pelo próprio serviço. O cliente envia o header `X-MOCK-ID` com o `_id` do documento e recebe o payload cadastrado — sem executar nenhuma lógica de negócio:

```json
{
  "_id": "checkout-mock",
  "description": "Mock resposta de checkout",
  "enabled": true,
  "payload": {
    "data": {
      "checkout": {
        "orderId": "order-001",
        "approved": true,
        "status": "PENDING"
      }
    }
  },
  "externalMockProperties": null
}
```

Uso via curl:
```bash
curl -X POST http://localhost:8080/my-service/checkout \
  -H "X-MOCK-ID: checkout-mock" \
  -H "Content-Type: application/json" \
  -d '{"orderId": "order-001"}'
```

---

### `kafka_messages_mock_inbound` — Eventos Kafka de entrada

Documentos que o serviço consome como se fossem mensagens Kafka recebidas. Campos esperados:

```json
{
  "topic": "order-created",
  "key": "order-001",
  "payload": { "orderId": "order-001", "total": 99.90 },
  "processed": false,
  "createdAt": "2024-01-15T10:00:00.000Z"
}
```

Na interface é possível criar novos eventos, usar um existente como modelo e reprocessar eventos já processados (reseta `processed` para `false`).

---

### `kafka_messages_mock` — Mensagens Kafka de saída

Visualização somente leitura das mensagens que o serviço publicou no Kafka durante o ambiente local. Campos esperados:

```json
{
  "topic": "order-confirmed",
  "key": "order-001",
  "value": { "orderId": "order-001", "status": "CONFIRMED" },
  "timestamp": "2024-01-15T10:05:00.000Z"
}
```

---

## Catálogo de Endpoints (opcional)

Se `ENDPOINTS_CATALOG_URL` estiver configurado, o formulário de criação de mock exibe um seletor de endpoints, preenchendo automaticamente o ID e o payload de exemplo.

A URL deve retornar um JSON no seguinte formato:

```json
[
  {
    "endpointId": "GET:/v1/products/stock-status",
    "description": "Consulta status de estoque",
    "type": "webclient",
    "examplePayload": {
      "productId": "prod-001",
      "available": true,
      "quantity": 42
    }
  },
  {
    "endpointId": "GET:/v1/orders/pricing",
    "description": "Consulta precificação de pedido",
    "type": "external",
    "examplePayload": {
      "orderId": "order-001",
      "finalPrice": 89.50
    }
  }
]
```

O campo `type` deve ser `webclient` ou `external` para aparecer na aba correta do formulário.

---

## Prioridade dos mocks

Quando existem mocks do tipo **Por Usuário** e **WebClient Genérico** para o mesmo endpoint, a precedência é:

1. **Por Usuário** — executado se o identificador estiver em `allowedUsers`
2. **WebClient Genérico** — executado quando o identificador não está em nenhum mock por usuário

O `_id` do mock genérico deve ser **idêntico** ao `externalMockProperties.endpointId` dos mocks por usuário para que a prioridade funcione corretamente.

A interface exibe avisos visuais nos cards quando há conflito entre os dois tipos para o mesmo endpoint.

---

## Estrutura de arquivos

```
mock-manager/
├── index.html          # Interface visual (abre direto no browser)
├── proxy.js            # Servidor Node.js que intermedia o MongoDB
├── databases.json      # Lista de databases e collections do projeto
├── config-padrao.txt   # Template de configuração (versionado)
├── config.txt          # Configuração local (ignorado pelo git)
├── start.bat           # Inicia o proxy e abre a interface
├── end.bat             # Encerra o proxy
├── package.json        # Dependências Node.js
└── .gitignore
```
