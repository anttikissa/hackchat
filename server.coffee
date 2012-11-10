#!/usr/bin/env coffee

express = require 'express'
sio = require 'socket.io'
http = require 'http'
compiler = require 'connect-compiler'
RedisStore = require('connect-redis')(express)

app = express()
server = http.createServer app
io = sio.listen server

sessionStore = new RedisStore(host: 'nodejitsudb6214129596.redis.irstack.com', pass: 'nodejitsudb6214129596.redis.irstack.com:f327cfe980c971946e80b8e975fbebb4')

app.set 'views', 'public'

secret = 'l6fsJUF)JH3JV6^'

app.use express.favicon()
app.use express.logger()
app.use express.cookieParser(secret)
app.use express.session(key: 's', store: sessionStore)
app.use compiler(enabled: ['coffee'], src: 'coffee', dest: 'public')
app.use express.static('public')

newNick = () ->
	t = new Date().getTime() % 456976
	"anon_" + t.toString(26)

app.use (req, resp, next) ->
	if not req.session.nick?
		nick = newNick()
		console.log "*** #{req.sessionID} is new user, giving nick #{nick}"
		req.session.nick = newNick()
	else
		console.log "*** #{req.sessionID} is returning user with nick #{req.session.nick}"

	next()

app.get '/', (req, resp) ->
	resp.render 'index.ejs', { nick: req.session.nick }

io.on 'connection', (socket) ->
	console.log "*** #{socket.id} connected"
	socket.on 'ping', (data) ->
		console.log "(#{socket.id}) PING #{JSON.stringify data}"
		socket.emit 'pong', data

server.listen 3000
console.log 'http://localhost:3000'
