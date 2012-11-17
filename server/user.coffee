_ = require 'underscore'

{ log, s, sanitizeChannel } = require '../lib/utils'
{ sessionStore } = require './sessionStore'
{ Channel } = require './channel'

# Utilities.

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
		@id = @sessionID
		# socket id -> socket
		@sockets = {}
		@channels = {}

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

	saveSession: ->
		sessionStore.set @sessionID, @session, (err) ->
			if err
				log.e "sessionStore.set #{@sessionID} error: #{err}"

	nick: ->
		@session.nick

	toString: ->
		"#{@session.nick} [#{@sessionID.substr(0,6)}]"

	info: (msg) ->
		@emit 'info', { msg: msg }

	emit: (what, data) ->
		for id, socket of @sockets
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

		log "*** #{this} is now known as #{newNick}."
		@session.nick = newNick
		@saveSession()
	
		@emit 'nick', { oldNick, newNick, you: true }
		@broadcast 'nick', { oldNick, newNick }

	say: (channelName, msg) ->
		if not channelName
			return @info "Please specify channel."
		if not msg
			return @info "Please specify message."

		channelName = sanitizeChannel channelName
		channel = @channels[channelName]
		if not channel
			return @info "You're not on channel ##{channelName}."

		channel.say this, msg

		# TODO where does this belong?
		log "*** <#{@nick()}:#{channel}> #{msg}"
		
	broadcast: (what, data) ->
		for id, channel of @channels
			channel.emit what, data

	join: (channel) ->
		if @channels[channel.id]
			return
		@channels[channel.id] = channel
		@session.channels = _.keys @channels
		@saveSession()

module.exports.User = User

