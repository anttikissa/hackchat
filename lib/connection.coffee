_ = require 'underscore'

nickUtil = require './nickUtil'
channels = require './channels'
channelUtil = require './channelUtil'
sessions = require './sessions'
Session = require('./sessionUtil').Session

Channel = channelUtil.Channel

# Remove any number of #'s from the beginning of the channel name.
sanitize = (channel) ->
	channel.replace /^#+/, ''

# Handles a connection with a single socket.io client (i.e. a browser window).

module.exports.connection = (sessionStore) ->
	(socket) ->
		sessionID = socket.handshake.sessionID
		session = socket.handshake.session

		sessions[sessionID] ?= new Session(sessionID)
		theSession = sessions[sessionID]
		sessions[sessionID].newConnection(socket)

		console.log "*** #{session.nick} @ #{socket.id} connected"

		sessionStore.on "#{sessionID} updated", (newSession) ->
			oldSession = session
			console.log "*** #{session.nick} @ #{socket.id}, updating session..."
			session = newSession
			console.log "*** #{session.nick} @ #{socket.id}, session updated."

			if session.nick != oldSession.nick
				# TODO find out all channels of this session
				# then emit to them
				socket.emit 'newNick',
					oldNick: oldSession.nick
					newNick: session.nick

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
				socket.emit 'info', { msg: "You're already known as #{newNick}." }
				return

			if nickUtil.validNick newNick
				if nickUtil.nickTaken newNick
					socket.emit 'info', { msg: "Nick already in use." }
				else
					newSession = _.extend {}, session, nick: newNick

					sessionStore.set sessionID, newSession, (err) ->
						if err
							console.log "Error saving session #{sessionID}"
					sessionStore.emit("#{sessionID} updated", newSession)

			else
				socket.emit 'info', { msg: "Invalid nick. Must be alphanumeric & at most 15 characters long." }

		socket.on 'say', ({ channel, msg }) ->
			if channels[channel]?.has sessionID
				console.log "*** <#{session.nick} #{channel}> #{msg}"
				channels[channel].emit 'say',
					nick: session.nick,
					channel: channel,
					msg: msg
			else
				socket.emit 'info', { msg: "You're not on #{channel}. Cannot say." }

		socket.on 'disconnect', ->
			console.log "*** #{session.nick} @ #{socket.id} disconnected"
			clearInterval greeter
			sessions[sessionID].connectionClosed(socket)

		names = (channel) ->
			if channels[channel]?
				channels[channel].sessions (err, sessions) ->
					socket.emit 'names', { channel: channel, names: _.pluck sessions, 'nick' }
			else
				socket.emit 'info', { msg: "No such channel #{channel}. Better luck next time." }

		socket.on 'names', ({ channel }) ->
			names channel

		socket.on 'join', ({ channel }) ->
			channel = sanitize channel

			if not channelUtil.validChannelName(channel)
				console.log "*** Invalid channel name ##{channel}"
				socket.emit 'info', { msg: "Invalid channel. Must be alphanumeric & at most 25 characters long." }
			else
				theChannel = (channels[channel] ?= new Channel(sessionStore, channel))
				if theChannel.join sessionID
					# TODO if we already were there?
					# better to push this logic into Channel?
					console.log "*** Channel #{channel}: #{theChannel.members.join ' '}"
					theChannel.emit 'join', { nick: session.nick, channel: channel }
					names channel
					theSession.joinChannel channel, socket
				else
#					socket.emit 'info', { msg: "You're already on that channel!" }
					theChannel.emit 'join', { nick: session.nick, channel: channel }

		socket.on 'leave', ({ channel }) ->
			channel = sanitize channel
			console.log "*** #{session.nick} leaving channel #{channel}, socket #{socket.id}"
			if channels[channel]?
				channels[channel].leave sessionID
				theSession.leaveChannel channel, socket
				socket.emit 'leave', { nick: session.nick, channel: channel }
			else
				console.log "*** #[socketID} tried to leave non-existing channel #{channel}"

		socket.emit 'info', { msg: "Welcome to HackChat!" }
		socket.emit 'info', { msg: "Type /help to get help." }

