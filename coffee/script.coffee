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
	if not channel?
		show "*** You're not on a channel - try joining one. /list shows available channels."
	else
		channel = channel.replace /^#+/, ''
		socket.emit 'say', channel: channel, msg: msg

show = (msg) ->
	$('.chat').append "<p>#{escapeHtml msg}</p>"

isCommand = (cmd) ->
	cmd.match /^\//

parseCommand = (cmd) ->
	[command, args...] = cmd.split /\s+/
	if command == '/'
		{ command: 'say', args: cmd.replace(/^\/\s+/, '') }
	else
		{ command: command.replace(/^\//, ''), args: args }

execute = (cmd) ->
	if isCommand cmd
		{ command, args } = parseCommand cmd
	else
		{ command, args } = { command: 'say', args: cmd }

	switch command
		when 'nick' then newNick args[0]
		when 'ping' then ping()
		when 'join' then join args[0]
		when 'say' then say mychannel, args
		else show "*** I don't know that command: #{command}."

mynick = null
mychannel = null
#"#foo"

$ ->
	mynick = $('.mynick').html()

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
		mynick = newNick

	socket.on 'error', ({ msg }) ->
		show "*** #{msg}"

	socket.on 'msg', ({ from, msg }) ->
		show "<#{from}> #{msg}"

	socket.on 'join', ({ nick, channel }) ->
		show "*** #{nick} has joined channel ##{channel}."
		if nick == mynick
			$('#sayChannel').val(channel)

	socket.on 'say', ({ nick, channel, msg }) ->
		show "<#{nick} ##{channel}> #{msg}"

	focus = ->
		$('#cmd').focus()# unless mousedown
	focus()
#	setInterval(focus, 300)

	$('#cmd').keypress (event) ->
		if event.keyCode == 13
			cmd = $(event.target).val()
			execute(cmd)
			$(event.target).val('')

socket = io.connect()

