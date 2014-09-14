express = require 'express'
httpProxy = require 'http-proxy'
serveStatic    = require 'serve-static'
path = require 'path'

proxy = httpProxy.createProxyServer({})
app = express()

app.use serveStatic path.join __dirname, '../src'

app.get "/api/*", (req, res) -> 
  proxy.web req, res, {target: 'http://ardusensor.com'}

server = app.listen 3000, ->
  console.log 'Listening on port %d', server.address().port