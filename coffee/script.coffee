$ ->
	$('body').append('<p>Hello from coffee</p>')
	socket.on 'connect', ->
		socket.emit('ping', { ts: new Date().getTime() })
	socket.on 'pong', (data) ->
		$('body').append("<p>PONG #{JSON.stringify data}")

socket = io.connect()


