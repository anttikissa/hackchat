{ log, s } = require '../lib/utils'

class Chat
	connections: {}

	constructor: () ->

	socketConnected: (socket) ->
		user = socket.user = socket.handshake.user
#		log.d "new socket #{socket.id} for user #{socket.user}"

		socket.on 'ping', (data) ->
			log "*** #{user} ping"
			socket.emit 'pong', data

		socket.on 'join', ({ channel }) ->
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
