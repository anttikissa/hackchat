module.exports =
	validNick: (nick) ->
		nick = nick.toLowerCase()
		okChars = nick.match /^[a-z0-9_]+$/
		okLength = nick.length <= 15
		okChars and okLength

	nickTaken: (nick) ->
		false

