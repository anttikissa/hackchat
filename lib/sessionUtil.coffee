_ = require 'underscore'

# Bad name.  Really just something that associates the session id with
# connections and channels.  But this information should be saved to redis as
# well.
class Session
	constructor: (@sessionID) ->
		# connections are sockets.
		@connections = []
		# channels are ids.
		# should be objects with a list of connections, possibly?
		@channels = []

	joinChannel: (channel, connection) ->
		@channels.push channel unless @channels in channel
		console.log "*** #{@sessionID} joins channel #{channel}"
		# TODO do whatever with the connection

	leaveChannel: (channel, connection) ->
		@channels = _.reject @channels, (aChannel) ->
			aChannel == channel
		# TODO handle the connection again...

	newConnection: (socket) ->
		@connections.push socket
		console.log "*** New connection! Now session #{@sessionID} has #{@connections.length} connections."

	connectionClosed: (socket) ->
		@connections = _.reject @connections, (aSocket) ->
			aSocket.id == socket.id
		console.log "*** Socket closed! Now session #{@sessionID} has #{@connections.length} connections."

module.exports.Session = Session

