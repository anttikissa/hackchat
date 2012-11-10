module.exports =
	validNick: (nick) ->
		okChars = nick.match /^[a-z0-9_]+$/
		okLength = nick.length < 16
		okChars and okLength

	nickTaken: (nick) ->
		false

