#!/usr/bin/env coffee

express = require 'express'
sio = require 'socket.io'

http = require 'http'

app = express()

server = http.createServer app

app.use express.static('public')

#server = http.createServer (req, res) ->
#  res.writeHead(200, {'Content-Type': 'text/plain'})
#  res.end('Hello World\n')

server.listen 3000

console.log 'http://localhost:3000'
