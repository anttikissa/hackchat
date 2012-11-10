ping = ->
	socket.emit('ping', { ts: new Date().getTime() })

newNick = (newNick) ->
	socket.emit('nick', { newNick: { newNick }})

show = (msg) ->
	$('body').append "<p>#{msg}</p>"

$ ->
	$('body').append('<p>Hello from coffee</p>')

	$('#ping').click ->
		ping()

	$('#newNick').click ->
		newNick($('#nick'))

	socket.on 'connect', ->
		ping()

	socket.on 'pong', (data) ->
		backThen = data.ts
		now = new Date().getTime()
		show "PONG #{JSON.stringify data}, roundtrip #{now - backThen} ms"

socket = io.connect()


