#!/usr/bin/env coffee

express = require 'express'
sio = require 'socket.io'
http = require 'http'
compiler = require 'connect-compiler'
RedisStore = require('connect-redis')(express)
cookie = require 'cookie'
parseSignedCookie = require('connect/lib/utils').parseSignedCookie

app = express()
server = http.createServer app
io = sio.listen server

io.set 'log level', 1

sessionStore = new RedisStore(host: 'nodejitsudb6214129596.redis.irstack.com', pass: 'nodejitsudb6214129596.redis.irstack.com:f327cfe980c971946e80b8e975fbebb4')

app.set 'views', 'views'

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

io.set 'authorization', (data, cb) ->
	cookieHeader = data.headers.cookie
	if not cookieHeader
		return cb "no cookies"
	parsedCookie = cookie.parse cookieHeader
	if not parsedCookie
		return cb "invalid cookies"
	sessionCookie = parsedCookie.s
	sessionID = parseSignedCookie sessionCookie, secret
	if not sessionID
		return cb "invalid session cookie"
	sessionStore.get sessionID, (err, session) ->
		if not session
			cb "no session"
		else
			data.sessionID = sessionID
			data.session = session
			cb null, true

validNick = (nick) ->
	okChars = nick.match /^[a-z0-9_]+$/
	okLength = nick.length < 16
	console.log "#{nick} chars #{okChars} len #{okLength}"
	okChars and okLength

nickTaken = (nick) ->
	false

io.on 'connection', (socket) ->
	sessionID = socket.handshake.sessionID
	session = socket.handshake.session
	console.log "*** #{session.nick} @ #{socket.id} connected"
	socket.on 'ping', (data) ->
		console.log "(#{session.nick} @ #{socket.id}) PING #{JSON.stringify data}"
		socket.emit 'pong', data
	socket.on 'newNick', ({ newNick }) ->
		console.log "*** #{session.nick} wants new nick: #{JSON.stringify newNick}"
		if validNick newNick
			if nickTaken newNick
				socket.emit 'error', { msg: "Nick already in use." }
			else
				session.nick = newNick
				socket.emit 'newNick', { newNick: newNick }
		else
			socket.emit 'error', { msg: "Invalid nick. Must be alphanumeric & at most 15 characters long." }

	socket.on 'disconnect', ->
		console.log "*** #{session.nick} @ #{socket.id} disconnected"

server.listen 3000
console.log 'http://localhost:3000'
