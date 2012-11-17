{ log } = require '../lib/utils'

class Channel
	constructor: (name) ->
		@name = name
		@id = name
		@users = {}
		log "new channel #{this}"

#	has: (user) ->
#		user.id of @users
#
	join: (user) ->
		@users[user.id] = user
#		@emit 'info', { msg: "#{user.nick()} has joined channel #{this}" }
		@emit 'join', nick: user.nick(), channel: @id

	say: (user, msg) ->
		@emit 'say', nick: user.nick(), channel: @id, msg: msg

	emit: (what, data) ->
		for id, user of @users
			user.emit what, data

	toString: ->
		"#" + @id

module.exports.Channel = Channel

