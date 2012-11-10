_ = require 'underscore'

class Session
	constructor: (@sessionID) ->
		# connections are sockets.
		@connections = []

	newConnection: (socket) ->
		@connections.push socket
		console.log "*** New connection! Now session #{@sessionID} has #{@connections.length} connections."

	connectionClosed: (socket) ->
		@connections = _.reject @connections, (aSocket) ->
			aSocket.id == socket.id
		console.log "*** Socket closed! Now session #{@sessionID} has #{@connections.length} connections."

module.exports.Session = Session

