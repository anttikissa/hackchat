#!/usr/bin/env coffee

express = require 'express'
sio = require 'socket.io'
http = require 'http'

app = express()
server = http.createServer app
io = sio.listen server

app.set 'views', 'public'

app.use express.favicon()
app.use express.logger()
app.get '/', (req, resp) ->
	resp.render 'index.ejs', { msg: 'hello' }

server.listen 3000
console.log 'http://localhost:3000'
