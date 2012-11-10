ping = ->
	socket.emit('ping', { ts: new Date().getTime() })

newNick = (newNick) ->
	socket.emit('newNick', { newNick: newNick })

show = (msg) ->
	$('body').append "<p>#{msg}</p>"

$ ->
	$('body').append('<p>Hello from coffee</p>')

	$('#ping').click ->
		ping()

	$('#newNick').click ->
		console.log "newNick"
		nick = $('#nick').val()
		console.log "change to #{nick}"
		newNick(nick)

	socket.on 'connect', ->
		ping()

	socket.on 'pong', (data) ->
		backThen = data.ts
		now = new Date().getTime()
		show "PONG #{JSON.stringify data}, roundtrip #{now - backThen} ms"
	
	socket.on 'newNick', ({ newNick }) ->
		show "Nick changed to #{newNick}"
		$('.mynick').html(newNick)

socket = io.connect()


