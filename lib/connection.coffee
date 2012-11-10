_ = require 'underscore'

nickUtil = require './nickUtil'
channels = require './channels'
channelUtil = require './channelUtil'
sessions = require './sessions'
Session = require('./sessionUtil').Session

Channel = channelUtil.Channel

# Handles a connection with a single socket.io client (i.e. a browser window).

module.exports.connection = (sessionStore) ->
	(socket) ->
		sessionID = socket.handshake.sessionID
		session = socket.handshake.session

		sessions[sessionID] ?= new Session(sessionID)
		sessions[sessionID].newConnection(socket)

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
		,	20000)

		socket.on 'ping', (data) ->
			console.log "(#{session.nick} @ #{socket.id}) PING #{JSON.stringify data}"
			socket.emit 'pong', data

		socket.on 'newNick', ({ newNick }) ->
#			console.log "*** #{session.nick} wants new nick: #{JSON.stringify newNick}"
			if newNick == session.nick
				return

			if nickUtil.validNick newNick
				if nickUtil.nickTaken newNick
					socket.emit 'error', { msg: "Nick already in use." }
				else
					newSession = _.extend {}, session, nick: newNick

					sessionStore.set sessionID, newSession, (err) ->
						if err
							console.log "Error saving session #{sessionID}"
					sessionStore.emit("#{sessionID} updated", newSession)

			else
				socket.emit 'error', { msg: "Invalid nick. Must be alphanumeric & at most 15 characters long." }

		socket.on 'say', ({ channel, msg }) ->
			if channels[channel]?.has sessionID
				console.log "*** <#{session.nick} #{channel}> #{msg}"
				channels[channel].emit 'say',
					nick: session.nick,
					channel: channel,
					msg: msg
			else
				socket.emit 'error', { msg: "You're not on #{channel}. Cannot say." }

		socket.on 'disconnect', ->
			console.log "*** #{session.nick} @ #{socket.id} disconnected"
			clearInterval greeter
			sessions[sessionID].connectionClosed(socket)

		socket.on 'join', ({ channel }) ->
#			console.log "*** #{session.nick} wants to join ##{channel}"
			channel = channel.replace /^#+/, ''

			if not channelUtil.validChannelName(channel)
				console.log "*** Invalid channel name ##{channel}"
				socket.emit 'error', { msg: "Invalid channel. Must be alphanumeric & at most 25 characters long." }
			else
				console.log "Valid channel name. Channels #{JSON.stringify channels}"
				theChannel = (channels[channel] ?= new Channel(channel))
				
				if theChannel.join sessionID
					# TODO if we already were there?
					# better to push this logic into Channel?
					console.log "*** Channel #{channel}: #{theChannel.members.join ' '}"
					# TODO should be sent to everyone
					socket.emit 'join', { nick: session.nick, channel: channel }

#			if channels[channel]?

