{ log, s } = require '../lib/utils'

newNick = () ->
	t = new Date().getTime() % 456976
	"anon_" + t.toString(26)

class User
	# sessionID -> User
	@users: { }

	# connect middleware for attaching/initializing user sessions
	@handleUserSession: (req, resp, next) =>
		@getUser(req.sessionID, req.session)
		next()

	# Called from HTTP and WebSocket entry points to make sure that we can
	# associate sessionID to an User object.
	@getOrInitUser: (sessionID, session) ->
		if not @users[sessionID]?
			user = new User(sessionID, session)
			@users[sessionID] = user
		@users[sessionID]

	constructor: (@sessionID, @session) ->
		log.d "### Creating new user for id #{sessionID}"

		if not @session.nick?
			nick = newNick()
			log "*** #{@sessionID} is new user, giving nick #{nick}"
			@session.nick = newNick()
		else
			log "*** #{@sessionID} is returning user with nick #{@session.nick}"

	toString: ->
		"#{@sessionID.substr(0,6)} <#{@session.nick}>"

	changeNick: (newNick) ->
		console.log "### User changing nick!"

module.exports.User = User

