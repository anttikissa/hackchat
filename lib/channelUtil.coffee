sessions = require './sessions'
_ = require 'underscore'

# ...
class Channel
	constructor: (@sessionStore, @name) ->
		# members are session ids.
		@members = []

	join: (sessionID) ->
		if sessionID in @members
			false
		else
			@members.push sessionID
			console.log "*** Channel #{@name} adding #{sessionID}"
			console.log "*** Now have users: #{@members.join ' '}"
			true
	
	leave: (sessionID) ->
		@members = _.without @members, sessionID
		console.log "*** Channel #{@name} removing #{sessionID}"
		console.log "*** Now have users: #{@members.join ' '}"

	has: (sessionID) ->
		sessionID in @members
	
	sessions: (cb) ->
		result = []
		membersLength = @members.length
		for sessionID in @members
			@sessionStore.get sessionID, (err, session) ->
				if err
					return cb err
				result.push session
				if result.length == membersLength
					return cb null, result
				

	emit: (what, data) ->
#		console.log "*** Channel ##{@name} emitting #{what}: #{JSON.stringify data}"
		for sessionID in @members
			theSession = sessions[sessionID]
			for socket in theSession.connections
#				console.log "*** Considering socket #{socket.id}."
				if theSession.isSocketListeningTo socket, @name
					socket.emit what, data
		
	hello: ->	
		console.log "Hello channel!"

module.exports.Channel = Channel
module.exports.validChannelName = (channel) ->
	okChars = channel.match /^[a-z0-9_]+$/
	okLength = channel.length <= 25
	okChars and okLength

