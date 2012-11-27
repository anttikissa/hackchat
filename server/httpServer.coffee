express = require 'express'
sio = require 'socket.io'
http = require 'http'
compiler = require 'connect-compiler'
cookie = require 'cookie'
parseSignedCookie = require('connect/lib/utils').parseSignedCookie
_ = require 'underscore'
fs = require 'fs'

{ log, s } = require '../lib/utils'
{ Chat } = require './chat'
{ User } = require './user'

{ sessionStore } = require './sessionStore'

# packageJson = require './package.json'
# would be nice but doesn't work on custom domain
packageJson = { version: '0.0.6' }

sessions = require './sessions'
sessionUtil = require './sessionUtil'
Session = sessionUtil.Session

#connection = require('./connection').connection(sessionStore)

chat = new Chat()

run = ->
	app = express()
	server = http.createServer app
	io = sio.listen server

	io.set 'log level', 1

	app.set 'views', 'client'

	secret = 'l6fsJUF)JH3JV6^'

	logfile = fs.createWriteStream('access.log', { flags: 'a' })
	app.use express.favicon()
	app.use express.logger(stream: logfile)
	app.use express.cookieParser(secret)
	app.use express.session(key: 's', store: sessionStore)
	app.use compiler {
		enabled: ['coffee', 'less'],
		roots: [['client', 'public']]
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
		if not req.session
			throw new Error("session is null, likely because redis down!")
		User.getOrInitUser(req.sessionID, req.session)
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
				data.user = User.getOrInitUser sessionID, session
				cb null, true

	io.on 'connection', (socket) ->
		chat.socketConnected socket

	server.listen 3000
	log.d 'Listening to http://localhost:3000'

module.exports.run = run

