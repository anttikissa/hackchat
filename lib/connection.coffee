_ = require 'underscore'

nick = require './nick'

console.dir nick

# Handles a connection with a single socket.io client (i.e. a browser window).

module.exports.connection = (sessionStore) ->
	(socket) ->
		sessionID = socket.handshake.sessionID
		session = socket.handshake.session
		console.log "*** #{session.nick} @ #{socket.id} connected"

		sessionStore.on "#{sessionID} updated", (newSession) ->
			oldSession = session
			console.log "*** #{session.nick} @ #{socket.id}, updating session..."
			session = newSession
			console.log "*** #{session.nick} @ #{socket.id}, session updated."

			if session.nick != oldSession.nick
				socket.emit 'newNick', { newNick: session.nick }

		greeter = setInterval(->
			console.log "Saying hello to #{session.nick} @ #{socket.id}"
			socket.emit 'msg', { from: 'server', msg: "hello #{session.nick}!" }
		,	1000)

		socket.on 'ping', (data) ->
			console.log "(#{session.nick} @ #{socket.id}) PING #{JSON.stringify data}"
			socket.emit 'pong', data

		socket.on 'newNick', ({ newNick }) ->
			console.log "*** #{session.nick} wants new nick: #{JSON.stringify newNick}"
			if nick.validNick newNick
				if nick.nickTaken newNick
					socket.emit 'error', { msg: "Nick already in use." }
				else
					newSession = _.extend {}, session, nick: newNick

					sessionStore.set sessionID, newSession, (err) ->
						if err
							console.log "Error saving session #{sessionID}"
					sessionStore.emit("#{sessionID} updated", newSession)

			else
				socket.emit 'error', { msg: "Invalid nick. Must be alphanumeric & at most 15 characters long." }

		socket.on 'disconnect', ->
			console.log "*** #{session.nick} @ #{socket.id} disconnected"
			clearInterval greeter
