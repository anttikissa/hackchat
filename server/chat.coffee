{ log, s } = require '../lib/utils'
{ Channel } = require './channel'

validChannelName = (channel) ->
	channel = channel.toLowerCase()
	okChars = channel.match /^[a-z0-9_-]+$/
	okLength = channel.length <= 25
	okChars and okLength

# Remove excess #'s from the beginning.
sanitizeChannel = (channel) ->
	channel.replace /^#+/, ''

class Chat
	constructor: () ->
		# id -> Channel
		@channels = {}

	socketConnected: (socket) ->
		user = socket.user = socket.handshake.user

		socket.on 'ping', (data) ->
			log "*** #{user} ping"
			socket.emit 'pong', data

		socket.on 'join', ({ channel }) =>
			if not channel
				return user.info "Please specify a channel to join."

			channelName = sanitizeChannel channel
			if not validChannelName channelName
				return user.info "Channels must be alphanumeric and at most 25 characters."
			if not @channels[channelName]
				@channels[channelName] = new Channel(channelName)
			channel = @channels[channelName]
			channel.join user
			user.join channel

		socket.on 'nick', ({ newNick }) ->
			user.changeNick(newNick)

		socket.on 'disconnect', =>
			@socketDisconnected socket

		user.socketConnected(socket)

	socketDisconnected: (socket) ->
		log.d "socket closed #{socket.id}"
		socket.user.socketDisconnected(socket)

module.exports.Chat = Chat
