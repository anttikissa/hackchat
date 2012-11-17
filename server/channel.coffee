{ log, s } = require '../lib/utils'

class Channel
	@channels: {}

	# Assume valid name
	@get: (name) ->
		if not @channels[name]
			@channels[name] = new Channel(name)
		@channels[name]
		
	constructor: (name) ->
#		log "Channel(#{name})"
		@name = name
		@id = name
		@users = {}

	join: (user, opts) ->
#		log "Channel.join #{user}, this #{this}"
		@users[user.id] = user
		unless opts?.silent
			@emit 'join', nick: user.nick(), channel: @id

	say: (user, msg) ->
		@emit 'say', nick: user.nick(), channel: @id, msg: msg

	emit: (what, data) ->
		for id, user of @users
			log "Channel.emit to user #{id} #{what}, #{s data}"
			user.emit what, data

	toString: ->
		"#" + @id

module.exports.Channel = Channel

