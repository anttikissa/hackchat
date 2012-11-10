# Utilities

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

	channel = sanitize channel
	socket.emit 'names', channel: channel

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
		when 'reconnect', 're' then io.connect()
		else show "*** I don't know that command: #{command}."

mynick = null
mychannel = null

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

	socket.on 'disconnect', ->
		show "*** Disconnected from server. Please stand by as I'm trying to reconnect..."

	socket.on 'connect', ->
		show "*** Connected to server."
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

	socket.on 'error', ({ msg }) ->
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

