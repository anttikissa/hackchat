_ = require 'underscore'

# Bad name.  Really just something that associates the session id with
# connections and channels.  But this information should be saved to redis as
# well.
class Session
	constructor: (@sessionID) ->
		# connections are sockets.
		@connections = []
		# channels maps channel names to a list of socket ids listening
		# to that channel.
		@channels = {}

	joinChannel: (channel, socket) ->
		if not @channels[channel]
			@channels[channel] = [socket.id]
		else
			@channels[channel].push socket.id unless socket.id in @channels[channel]

#		@channels.push channel unless @channels in channel
#		console.log "*** #{@sessionID} joins channel #{channel} with #{socket.id}."
#		console.log "*** @channels is now #{JSON.stringify @channels}"

	# Whether we should send data from channel to the given socket
	# what belongs to this session.  If it sounds a bit complicated, it is.
	# "Sorry to write such a long letter; I didn't have the time to write a
	# short one."
	isSocketListeningTo: (socket, channel) ->
#		console.log "### isSocketListeningTo #{socket.id}, #{channel}"
#		console.log "*** @channels is now #{JSON.stringify @channels}"
		if not @channels[channel]
#			console.log "### false"
			false
		else
			result = socket.id in @channels[channel]
#			console.log "### it's #{result}"
			result

	# Return whether we're leaving for good.
	leaveChannel: (channel, socket) ->
		if @channels[channel]
			@channels[channel] = _.without @channels[channel], socket.id
			
		if @channels[channel].length == 0
			delete @channels[channel]
			result = true
		else
			result = false

#		console.log "*** #{@sessionID} leaves channel #{channel} with #{socket.id}"
#		console.log "*** @channels is now #{JSON.stringify @channels}"
		result

	newConnection: (socket) ->
		@connections.push socket
#		console.log "*** New connection! Now session #{@sessionID} has #{@connections.length} connections."

	connectionClosed: (socket) ->
		@connections = _.reject @connections, (aSocket) ->
			aSocket.id == socket.id
#		console.log "*** 1. @channels is now #{JSON.stringify @channels}"
		for channel, connections of @channels
#			console.log "### CLOSED, removing #{socket.id} from channel #{channel}"
			@channels[channel] = _.without connections, socket.id

		if @channels[channel] && @channels[channel].length == 0
			delete @channels[channel]

#		console.log "*** 2. @channels is now #{JSON.stringify @channels}"
#		console.log "*** Socket closed! Now session #{@sessionID} has #{@connections.length} connections."

module.exports.Session = Session

