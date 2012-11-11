# Utilities

connected = false
socket = io.connect()

escapeHtml = (s) ->
	s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
	.replace(/"/g, "&quot;") .replace(/'/g, "&#039;")

# Remove any number of #'s from the beginning of the channel name.
sanitize = (channel) ->
	channel.replace /^#+/, ''

ping = ->
	socket.emit 'ping', ts: new Date().getTime()

newNick = (newNick) ->
	socket.emit 'newNick', newNick: newNick

join = (channel) ->
	channel = sanitize channel
	socket.emit 'join', channel: channel

names = (channel) ->
	channel ?= mychannel

	if not channel
		show '*** Please specify channel.'
	else
		channel = sanitize channel
		socket.emit 'names', channel: channel

reconnect = ->
	if connected
		show "*** Disconnecting."
		socket.disconnect()

	# Incredible hack to recover socket.io.
	uri = io.util.parseUri()
	uuri = null

	if window && window.location
		uri.protocol = uri.protocol || window.location.protocol.slice(0, -1)
		uri.host = uri.host || (if window.document then window.document.domain else window.location.hostname)
		uri.port = uri.port || window.location.port

	uuri = io.util.uniqueUri(uri)
		
	show "*** Reconnecting to #{uuri}."
	delete io.sockets[uuri]
	socket = io.connect()
	initSocket()

help = (help) ->
	show "*** Available commands:"
	show "*** /nick <nick> - change nick."
#	show "*** /list - show channels"
	show "*** /say <message> - say on current channel."
	show "*** /join <channel> - join a channel. Alias: /j"
	show "*** /names [<channel>] - show who's on a channel"
#	show "*** /whois [<nick>] - show info about a person"
#	show "*** /leave [<channel>] - leave a channel (current channel by default)"
#	show "*** /msg <nick> <message> - send private message to <nick>"
	show "*** /help - here we are. Alias: /h"
	show "*** /ping - ping the server."
	show "*** /reconnect - try to connect to the server we're not connected."

say = (channel, msg) ->
	if not channel?
		show "*** You're not on a channel - try joining one. /list shows available channels."
	else
		channel = sanitize channel
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
		when 'join', 'j' then join args[0]
		when 'names', 'n' then names (args[0] ? mychannel)
		when 'say', 's' then say mychannel, args
		when 'help', 'h' then help args
		when 'reconnect', 're', 'reco' then reconnect()
#		when 'leave', 'le', 'part' then leave()
		else show "*** I don't know that command: #{command}."

mynick = null
mychannel = null

initSocket = () ->
	socket.on 'disconnect', ->
		show "*** Disconnected from server."
		connected = false

	socket.on 'connect', ->
		show "*** Connected to server."
		connected = true
		ping()

	socket.on 'names', ({ channel, names }) ->
		names.sort()
		show "*** There are #{names.length} people on ##{channel}:"
		show "*** #{names.join ' '}"
		
	socket.on 'pong', (data) ->
		backThen = data.ts
		now = new Date().getTime()
		show "PONG #{JSON.stringify data}, roundtrip #{now - backThen} ms"

	socket.on 'newNick', ({ oldNick, newNick }) ->
		if oldNick == mynick
			show "*** You are now known as #{newNick}."
			mynick = newNick
			$('.mynick').html(newNick)
		else
			show "*** #{oldNick} is now known as #{newNick}."

	socket.on 'error', (data) ->
		show "*** Failed to reconnect. Please try again later."
		# simply ignore it.
#		show "*** socket.io error: #{JSON.stringify data}"

	socket.on 'info', ({ msg }) ->
		show "*** #{msg}"

	socket.on 'msg', ({ from, msg }) ->
		show "<#{from}> #{msg}"

	socket.on 'join', ({ nick, channel }) ->
		show "*** #{nick} has joined channel ##{channel}."
		# TODO This is not a tenable solution.
		if nick == mynick
			$('mychannel').val(channel)
			mychannel = channel

	socket.on 'say', ({ nick, channel, msg }) ->
		show "<#{nick} ##{channel}> #{msg}"

$ ->
	mynick = $('.mynick').html()

	initSocket()

	$('#ping').click ->
		ping()

	$('#nick').change ->
		newNick($('#nick').val())

	$('#channel').change ->
		join($('#channel').val())

	$('#msg').change ->
		say($('#sayChannel').val(), $('#msg').val())

	focus = ->
		$('#cmd').focus()# unless mousedown
	focus()
#	setInterval(focus, 300)

	$('#cmd').keypress (event) ->
		if event.keyCode == 13
			cmd = $(event.target).val()
			execute(cmd)
			$(event.target).val('')

