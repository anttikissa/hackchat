escapeHtml = (s) ->
	s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
	.replace(/"/g, "&quot;") .replace(/'/g, "&#039;")

ping = ->
	socket.emit 'ping', ts: new Date().getTime()

newNick = (newNick) ->
	socket.emit 'newNick', newNick: newNick

join = (channel) ->
	socket.emit 'join', channel: channel

say = (channel, msg) ->
	socket.emit 'say', channel: channel, msg: msg

show = (msg) ->
	$('body').append "<p>#{escapeHtml msg}</p>"

mynick = null

$ ->
	mynick = $('.mynick').html()

	$('body').append('<p>Hello from coffee</p>')

	$('#ping').click ->
		ping()

	$('#nick').change ->
		newNick($('#nick').val())

	$('#channel').change ->
		join($('#channel').val())

	$('#msg').change ->
		say($('#sayChannel').val(), $('#msg').val())

	socket.on 'connect', ->
		ping()

	socket.on 'pong', (data) ->
		backThen = data.ts
		now = new Date().getTime()
		show "PONG #{JSON.stringify data}, roundtrip #{now - backThen} ms"
	
	socket.on 'newNick', ({ newNick }) ->
		show "Nick changed to #{newNick}"
		$('.mynick').html(newNick)

	socket.on 'error', ({ msg }) ->
		show "*** #{msg}"

	socket.on 'msg', ({ from, msg }) ->
		show "<#{from}> #{msg}"

	socket.on 'join', ({ nick, channel }) ->
		show "*** #{nick} has joined channel ##{channel}."
		if nick == mynick
			$('#sayChannel').val(channel)

socket = io.connect()


