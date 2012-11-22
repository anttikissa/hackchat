{ log, s } = require '../lib/utils'

class Channel
	@channels: {}

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
		@users = {}

	join: (user, opts) ->
#		log "Channel.join #{user}, this #{this}"
		@users[user.id] = user
		unless opts?.silent
			@emit 'join', nick: user.nick(), channel: @id

	leave: (user, message) ->
		@emit 'leave', {
			nick: user.nick()
			channel: @id
			message: message
		}
		delete @users[user.id]
		# TODO save users of channel to somewhere
		# TODO if no users on channel, get channel removed

	say: (nick, msg) ->
#		log "this is #{s this.users}"
		console.log "say: nick #{nick}"
		@emit 'say', nick: nick, channel: @id, msg: msg

	emit: (what, data) ->
#		log "Channel #{this}: emit <#{what}> #{s data}. @users follows"
		for id, user of @users
#			log "Channel.emit to user #{id} #{what}, #{s data}"
			user.emit what, data

	toString: ->
		"#" + @id

module.exports.Channel = Channel

