_ = require 'underscore'

{ log, s } = require '../lib/utils'
{ sessionStore } = require './sessionStore'

# Nick utilities.

validNick = (nick) ->
	nick = nick.toLowerCase()
	okChars = nick.match /^[a-z0-9_]+$/
	okLength = nick.length <= 15
	okChars and okLength

nickTaken = (nick) ->
	false

newNick = () ->
	t = new Date().getTime() % 456976
	"anon_" + t.toString(26)

class User
	# sessionID -> User
	@users: { }

	# Called from HTTP and WebSocket entry points to make sure that we can
	# associate sessionID to an User object.
	@getOrInitUser: (sessionID, session) ->
		if not @users[sessionID]?
			user = new User(sessionID, session)
			@users[sessionID] = user
		@users[sessionID]

	constructor: (@sessionID, @session) ->
		# socket id -> socket
		@sockets = {}

		log.d "Creating new user for id #{sessionID}"

		if not @session.nick?
			nick = newNick()
			log.d "#{@sessionID} is new user, giving nick #{nick}"
			@session.nick = newNick()
		else
			log.d "#{@sessionID} is returning user with nick #{@session.nick}"

	socketConnected: (socket) ->
		@sockets[socket.id] = socket
		log.d "#{this}: connected. Sockets: #{_.keys(@sockets).join ' '}"

	socketDisconnected: (socket) ->
		delete @sockets[socket.id]
		log.d "#{this}: socket disconnected. Sockets: #{_.keys(@sockets).join ' '}"

	toString: ->
		"#{@session.nick} [#{@sessionID.substr(0,6)}]"

	info: (msg) ->
		emit 'info', { msg: msg }

	emit: (what, data) ->
		for id, socket of @sockets
			console.log "Emitting to #{id}: #{what} #{s data}"
			socket.emit what, data

	# Commands sent by client
	changeNick: (newNick) ->
		oldNick = @session.nick

		if newNick == oldNick
			return @info "You're already known as #{newNick}."

		if !validNick newNick
			return @info "Invalid nick. Must be alphanumeric and at most 15 characters long."
		if nickTaken newNick
			return @info "Nick already in use."

		log "*** #{this} is now known as #{newNick}"
		@session.nick = newNick
		sessionStore.set @sessionID, @session, (err) ->
			if err
				log.e "sessionStore.set #{@sessionID} error: #{err}"
	
		@emit 'nick', { oldNick: oldNick, newNick: newNick, you: true }
		# TODO broadcast on user's channels, too
	
	join: (channel) ->
		log "User joining #{channel}"

module.exports.User = User

