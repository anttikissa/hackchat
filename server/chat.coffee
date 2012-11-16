
class Chat
	constructor: (@sessionStore) ->

	socketConnected: (socket) ->
		console.log "new socket #{socket.id}"
#		socket.on 'message', (msg) ->
#			console.log "msg here #{msg}"
		socket.on 'ping', (data) ->
			socket.emit 'pong', data
		socket.on 'disconnect', =>
			@socketDisconnected socket

	socketDisconnected: (socket) ->
		console.log "socket closed #{socket.id}"

module.exports.Chat = Chat
