{ log } = require '../lib/utils'

class Chat
	connections: {}

	constructor: () ->

	socketConnected: (socket) ->
		socket.user = socket.handshake.user
#		@connections[socket.id] = 
		log.d "new socket #{socket.id} for user #{socket.user}"
		socket.on 'ping', (data) ->
			socket.emit 'pong', data
		socket.on 'nick', ({ newNick }) ->
			socket.user.changeNick(newNick)
		socket.on 'disconnect', =>
			@socketDisconnected socket

	socketDisconnected: (socket) ->
		log.d "socket closed #{socket.id}"

module.exports.Chat = Chat
