_ = require 'underscore'

{ log, s, sanitizeChannel } = require '../lib/utils'
{ Channel } = require './channel'
{ User } = require './user'

validChannelName = (channel) ->
	channel = channel.toLowerCase()
	okChars = channel.match /^[a-z0-9_-]+$/
	okLength = channel.length <= 25
	okChars and okLength

debug = true

class Chat
	constructor: () ->

	socketConnected: (socket) ->
		user = socket.user = socket.handshake.user

		leave = (channelName, message) =>
			log "*** #{user} leaving #{channelName}"
		
			channel = Channel.getIfExists sanitizeChannel channelName
			if not channel
				user.info "No such channel #{channelName}"
			else
				channel.leave user, message
				channel.unlisten socket.id
				user.leave channel

		protocol =
			ping: (data) ->
				log "*** #{user} ping"
				socket.emit 'pong', data

			join: ({ channel, silent }) =>
				# TODO this should go somewhere else, possibly?
				# Where to handle error checking exactly, since it's not logically
				# part of User or Channel? Just pick one?
				# User.join would probably be it.
				if not channel
					return user.info "Please specify a channel to join."

				channelName = sanitizeChannel channel
				if not validChannelName channelName
					return user.info "Channels must be alphanumeric and at most 25 characters."
				channel = Channel.get channelName
				channel.join user, silent: silent
				channel.listen user, socket.id
				user.join channel
				log "*** #{user.nick()} has joined channel #{channel}."

			listen: ({ channel }) =>
				if not channel
					return user.info "Please specify a channel to listen."
				channelName = sanitizeChannel channel
				if not validChannelName channelName
					return user.info "Channels must be alphanumeric and at most 25 characters."
				channel = Channel.get channelName
				channel.listen user, socket.id

			# TODO combine channel name handling between join, listen and this
			unlisten: ({ channel }) =>
				if not channel
					return user.info "Please specify a channel to listen."
				channelName = sanitizeChannel channel
				if not validChannelName channelName
					return user.info "Channels must be alphanumeric and at most 25 characters."
				channel = Channel.get channelName
				channel.unlisten socket.id
				
			names: ({ channel }) ->
				channelName = sanitizeChannel channel
				channel = Channel.getIfExists channelName

				if channel
					user.emit 'names', {
						channel: channelName
						names: user.nick() for userId, user of channel.users
					}
				else
					user.info "No such channel #{channelName}"

			leave: ({ channel, message }) ->
				if not channel
					return user.info "Please specify a channel to leave."
				channelName = sanitizeChannel channel
				if not validChannelName channelName
					return user.info "Invalid channel name."

				leave channelName, message

			nick: ({ newNick }) =>
				result = user.changeNick(newNick)
				if result
					{ oldNick, newNick } = result
					delete User.nicks[oldNick]
					User.nicks[newNick] = user

			whois: ({ nick }) =>
				other = User.nicks[nick]
				if other
					user.emit 'info', msg: "TODO whois #{nick}"
					user.emit 'channels', nick: nick, channels: other.channelList()
				else
					user.emit 'info', msg: "No such nick #{nick}"

			say: ({ channel, msg }) ->
				user.say channel, msg
				
			disconnect: =>
				@socketDisconnected socket
	
		for what, action of protocol
			do (what, action) ->
				socket.on what, (data) ->
					if debug
						if data?
							log "<= #{user} '#{what}': #{s data}"
						else
							log "<= #{user} '#{what}'"
					action data

		user.socketConnected(socket)

	socketDisconnected: (socket) ->
		# TODO unlisten to all channels
		# TODO possibly leave some of the channels (or not?)
		log.d "socket closed #{socket.id}"
		socket.user.socketDisconnected(socket)

module.exports.Chat = Chat
