#!/usr/bin/env coffee

express = require 'express'
sio = require 'socket.io'
http = require 'http'
compiler = require 'connect-compiler'

app = express()
server = http.createServer app
io = sio.listen server

app.set 'views', 'public'

app.use express.favicon()
app.use express.logger()
app.use compiler(enabled: ['coffee'], src: 'coffee', dest: 'public')
app.use express.static('public')
app.get '/', (req, resp) ->
	resp.render 'index.ejs', { msg: 'hello' }

io.on 'connection', (socket) ->
	console.log "*** #{socket.id} connected"
	socket.on 'ping', (data) ->
		console.log "(#{socket.id}) PING #{JSON.stringify data}"
		socket.emit 'pong', data

server.listen 3000
console.log 'http://localhost:3000'
