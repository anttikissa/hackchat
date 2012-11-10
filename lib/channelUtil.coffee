sessions = require './sessions'

# ...
class Channel
	constructor: (@name) ->
		# members are session ids.
		@members = []

	join: (sessionID) ->
		if sessionID in @members
			false
		else
			@members.push sessionID
			true

	has: (sessionID) ->
		sessionID in @members

	emit: (what, data) ->
		for sessionID in @members
			theSession = sessions[sessionID]
			for socket, idx in theSession.connections
				console.log "### send #{what} to #{sessionID}, socket #{idx}..."
				socket.emit what, data
		
	hello: ->	
		console.log "Hello channel!"

module.exports.Channel = Channel
module.exports.validChannelName = (channel) ->
	okChars = channel.match /^[a-z0-9_]+$/
	okLength = channel.length <= 25
	okChars and okLength

