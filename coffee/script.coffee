ping = ->
	socket.emit('ping', { ts: new Date().getTime() })

$ ->
	$('body').append('<p>Hello from coffee</p>')
	$('button').click ->
		ping()

	socket.on 'connect', ->
		ping()

	socket.on 'pong', (data) ->
		backThen = data.ts
		now = new Date().getTime()

		$('body').append("<p>PONG #{JSON.stringify data}, roundtrip #{now - backThen} ms")

socket = io.connect()


