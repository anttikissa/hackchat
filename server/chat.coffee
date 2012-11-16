{ log } = require '../lib/utils'

class Chat
	connections: {}

	constructor: (@sessionStore) ->

	socketConnected: (socket) ->
#		@connections[socket.id] = 
		log.d "new socket #{socket.id} for user #{socket.handshake.user}"
		socket.on 'ping', (data) ->
			socket.emit 'pong', data
		socket.on 'disconnect', =>
			@socketDisconnected socket

	socketDisconnected: (socket) ->
		log.d "socket closed #{socket.id}"

module.exports.Chat = Chat
