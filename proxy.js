const fs = require('fs')
const http = require('http')
const https = require('https')
const { MongoClient, ObjectId } = require('mongodb')

const config = fs.existsSync('./config.txt')
  ? Object.fromEntries(fs.readFileSync('./config.txt', 'utf-8').split('\n').filter(l => l.includes('=')).map(l => l.trim().split('=')))
  : fs.existsSync('./config-padrao.txt')
  ? Object.fromEntries(fs.readFileSync('./config-padrao.txt', 'utf-8').split('\n').filter(l => l.includes('=')).map(l => l.trim().split('=')))
  : {}
const PORT = parseInt(config.PORT || '3333')
const ENDPOINTS_CATALOG_URL = config.ENDPOINTS_CATALOG_URL?.trim() || ''
const ALLOW_DELETE = (config.ALLOW_DELETE?.trim() || 'true') === 'true'
let client = null
let db = null

const cors = (res) => {
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS')
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type')
}

const send = (res, status, data) => {
  cors(res)
  res.writeHead(status, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify(data))
}

const parseBody = (req) => new Promise((resolve, reject) => {
  let body = ''
  req.on('data', chunk => body += chunk)
  req.on('end', () => { try { resolve(JSON.parse(body)) } catch { reject(new Error('Invalid JSON')) } })
})

const resolveId = (id) => {
  try { return new ObjectId(id) } catch { return id }
}

http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') { cors(res); res.writeHead(204); res.end(); return }
  if (req.method !== 'POST') { send(res, 405, { error: 'Method not allowed' }); return }

  try {
    const body = await parseBody(req)

    if (req.url === '/config') {
      send(res, 200, { allowDelete: ALLOW_DELETE })
      return
    }

    if (req.url === '/get-config') {
      const raw = fs.existsSync('./config.txt') ? fs.readFileSync('./config.txt', 'utf-8') : fs.readFileSync('./config-padrao.txt', 'utf-8')
      const data = Object.fromEntries(raw.split('\n').filter(l => l.includes('=')).map(l => { const [k, ...v] = l.trim().split('='); return [k, v.join('=')] }))
      send(res, 200, data)
      return
    }

    if (req.url === '/save-config') {
      const { PORT: p, ENDPOINTS_CATALOG_URL: u, ALLOW_DELETE: ad } = body
      if (!p) { send(res, 400, { error: 'PORT é obrigatório' }); return }
      const content = `PORT=${p}\nENDPOINTS_CATALOG_URL=${u || ''}\nALLOW_DELETE=${ad === false || ad === 'false' ? 'false' : 'true'}\n`
      fs.writeFileSync('./config.txt', content, 'utf-8')
      send(res, 200, { ok: true })
      return
    }

    if (req.url === '/save-databases') {
      const { databases } = body
      if (!Array.isArray(databases)) { send(res, 400, { error: 'databases deve ser um array' }); return }
      fs.writeFileSync('./databases.json', JSON.stringify(databases, null, 2), 'utf-8')
      send(res, 200, { ok: true })
      return
    }

    if (req.url === '/catalog') {
      if (!ENDPOINTS_CATALOG_URL) { send(res, 404, { error: 'ENDPOINTS_CATALOG_URL not configured' }); return }
      const fetchUrl = new URL(ENDPOINTS_CATALOG_URL)
      const lib = fetchUrl.protocol === 'https:' ? https : http
      lib.get(ENDPOINTS_CATALOG_URL, r => {
        let data = ''
        r.on('data', chunk => data += chunk)
        r.on('end', () => {
          try { send(res, 200, { endpoints: JSON.parse(data) }) }
          catch { send(res, 500, { error: 'Invalid response from catalog API' }) }
        })
      }).on('error', e => send(res, 500, { error: e.message }))
      return
    }

    if (req.url === '/databases') {
      const list = JSON.parse(fs.readFileSync('./databases.json', 'utf-8'))
      send(res, 200, { databases: list })
      return
    }

    if (req.url === '/connect') {
      const { uri, database } = body
      if (!uri || !database) { send(res, 400, { error: 'uri and database are required' }); return }
      const isConnected = client?.topology?.isConnected()
      if (!isConnected) {
        if (client) await client.close().catch(() => {})
        client = new MongoClient(uri)
        await client.connect()
      }
      db = client.db(database)
      await db.command({ ping: 1 })
      send(res, 200, { ok: true })
      return
    }

    if (!db) { send(res, 401, { error: 'Not connected' }); return }

    const col = db.collection(body.collection)

    if (req.url === '/find') {
      const docs = await col.find(body.filter || {}).limit(body.limit || 200).toArray()
      send(res, 200, { documents: docs })
      return
    }

    if (req.url === '/insertOne') {
      const result = await col.insertOne(body.document)
      send(res, 200, { insertedId: result.insertedId })
      return
    }

    if (req.url === '/updateOne') {
      const filter = body.filter?._id ? { _id: resolveId(body.filter._id) } : body.filter
      const result = await col.updateOne(filter, body.update)
      send(res, 200, { modifiedCount: result.modifiedCount })
      return
    }

    if (req.url === '/deleteOne') {
      const filter = body.filter?._id ? { _id: resolveId(body.filter._id) } : body.filter
      const result = await col.deleteOne(filter)
      send(res, 200, { deletedCount: result.deletedCount })
      return
    }

    send(res, 404, { error: 'Unknown action' })
  } catch (e) {
    send(res, 500, { error: e.message })
  }
}).listen(PORT, () => console.log(`Mock Manager Proxy: http://localhost:${PORT}`))
