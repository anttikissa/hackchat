{ log } = require '../lib/utils'

class Chat
	constructor: (@sessionStore) ->

	socketConnected: (socket) ->
		log.d "new socket #{socket.id}"
		socket.on 'ping', (data) ->
			socket.emit 'pong', data
		socket.on 'disconnect', =>
			@socketDisconnected socket

	socketDisconnected: (socket) ->
		log.d "socket closed #{socket.id}"

module.exports.Chat = Chat
