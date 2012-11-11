#!/usr/bin/env coffee

express = require 'express'
sio = require 'socket.io'
http = require 'http'
compiler = require 'connect-compiler'
RedisStore = require('connect-redis')(express)
cookie = require 'cookie'
parseSignedCookie = require('connect/lib/utils').parseSignedCookie
_ = require 'underscore'

# packageJson = require './package.json'
# would be nice but doesn't work on custom domain
packageJson = { version: '0.0.5' }

sessions = require './lib/sessions'
sessionUtil = require './lib/sessionUtil'
Session = sessionUtil.Session

app = express()
server = http.createServer app
io = sio.listen server

io.set 'log level', 1

sessionStore = new RedisStore(host: 'nodejitsudb6214129596.redis.irstack.com', pass: 'nodejitsudb6214129596.redis.irstack.com:f327cfe980c971946e80b8e975fbebb4')
sessionStore.setMaxListeners(1024)

connection = require('./lib/connection').connection(sessionStore)

app.set 'views', 'views'

secret = 'l6fsJUF)JH3JV6^'

app.use express.favicon()
app.use express.logger()
app.use express.cookieParser(secret)
app.use express.session(key: 's', store: sessionStore)
app.use compiler {
	enabled: ['coffee', 'less'],
	roots: [['coffee', 'public'], ['styles', 'public']]
}
app.use express.static('public')

newNick = () ->
	t = new Date().getTime() % 456976
	"anon_" + t.toString(26)

app.use (req, resp, next) ->
	host = req.header('host')

	if host
		if host.match /^www\./i
			resp.redirect 301, "http://#{host.replace(/^www\./i, '')}/"
		else
			next()
	else
		resp.send 'Fail', 404

app.use (req, resp, next) ->
	if not req.session.nick?
		nick = newNick()
		console.log "*** #{req.sessionID} is new user, giving nick #{nick}"
		req.session.nick = newNick()
	else
		console.log "*** #{req.sessionID} is returning user with nick #{req.session.nick}"

	next()

app.get '/', (req, resp) ->
	resp.render 'index.ejs', {
		nick: req.session.nick
		version: packageJson.version
	}

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

io.on 'connection', connection

server.listen 3000
console.log 'http://localhost:3000'
