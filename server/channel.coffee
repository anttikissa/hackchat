{ log, s } = require '../lib/utils'

class Channel
	@channels: Object.create null

	# Assume valid name
	@get: (name) ->
		if not @channels[name]
			@channels[name] = new Channel(name)
		@channels[name]

	@getIfExists: (name) ->
		@channels[name]

	constructor: (name) ->
#		log "Channel(#{name})"
		@name = name
		@id = name
		@users = Object.create null
		# Those sockets who want to receive channel messages.
		# @emit() will distributes messages to them.
		# Map of socket ids to user objects.
		@listeners = Object.create null

	join: (user, opts) ->
#		log "Channel.join #{user}, this #{this}"
		alreadyThere = @users[user.id]?
		@users[user.id] = user
		if alreadyThere
			user.info "You're already on channel #{this}."
		else
			unless opts?.silent
				@emit 'join', nick: user.nick(), channel: @id

	listen: (user, socketId) ->
		alreadyThere = @listeners[socketId]?
		@listeners[socketId] = user

		if alreadyThere
			user.emitToSocket socketId,
				'info',
				{ msg: "You're already listening to channel #{this}." }
		else
			if @users[user.id]
				# Should really emitToSocket to that socket!
#				user.info "Now listening to channel #{this}."
				# TODO here we should only emit to the right socket.
				user.emitToSocket socketId,
					'listen',
					# TODO you should be unnecessary
					{ nick: user.nick(), channel: @id, you: true }
			else
				user.info "You're not on channel #{this}, cannot listen."
				#{user.id} not on channel #{this}, yet is trying to listen to it! Should not happen!"
				# TODO or just complain to the user directly.

	unlisten: (socketId) ->
		user = @listeners[socketId]
		if user
			user.info "No longer listening to channel #{this}."
		delete @listeners[socketId]

	leave: (user, message) ->
		@emit 'leave', {
			nick: user.nick()
			channel: @id
			message: message
		}
		# TODO unlisten to all sockets of user
		delete @users[user.id]
		# TODO save users of channel to somewhere
		# TODO if no users on channel, get channel removed

	say: (nick, msg) ->
#		log "this is #{s this.users}"
		console.log "say: nick #{nick}"
		@emit 'say', nick: nick, channel: @id, msg: msg

	emit: (what, data) ->
		log "Channel #{this} broadcasting #{what} to listening sockets."
		for socketId, user of @listeners
			log "Listener #{socketId}, user #{user}"
			user.emitToSocket socketId, what, data
		# for id, user of @users
		#	user.emit what, data

	toString: ->
		"#" + @id

module.exports.Channel = Channel

