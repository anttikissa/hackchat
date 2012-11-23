# Utilities

log = -> console.log arguments...
s = -> JSON.stringify arguments...

# Remove any number of #'s from the beginning of the channel name.
sanitize = (channel) ->
	channel.replace /^#+/, ''

connected = false
socket = io.connect()

# Channel management

# List of all channels this socket is on.
channels = []

# Command history.
history = []
historyIdx = 0
newestCommand = ''

# Mirror the html elements of respective classes.
mynick = null
mychannel = null

addChannel = (channel) ->
	channels.push channel
#	location.hash = channels.join ','
	$('.ifchannel').show()

# Remove channel from list, return channel next to it
removeChannel = (channel) ->
	idx = channels.indexOf channel
	if idx != -1
		channels.splice idx, 1
#	location.hash = channels.join ','
	if channels.length == 0
		$('.ifchannel').hide()
		return null
	else
		return channels[(idx - 1 + channels.length) % channels.length]

setChannel = (next) ->
	console.log "setChannel #{next}"
	mychannel = next
	if next
#		console.log "mychannel is now #{next}"
		$('.mychannel').html('#' + next)
		$('.ifchannel').show()
	else
		$('.mychannel').html('')
		$('.ifchannel').hide()

next = () ->
	if channels.length <= 1 || not mychannel
		return
	newChannel = channels[(channels.indexOf(mychannel) + 1) % channels.length]
	setChannel(newChannel)

prev = () ->
	if channels.length <= 1 || not mychannel
		return
	newChannel = channels[(channels.indexOf(mychannel) - 1 + channels.length) % channels.length]
	setChannel(newChannel)

escapeHtml = (s) ->
	s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
	.replace(/"/g, "&quot;") .replace(/'/g, "&#039;")

debug = true

emit = (what, msg) ->
	if debug
		show "=> '#{what}': #{JSON.stringify msg}"
	socket.emit what, msg

ping = ->
	emit 'ping', ts: new Date().getTime()

newNick = (newNick) ->
	emit 'nick', newNick: newNick

join = (channel) ->
	channel = sanitize channel
	emit 'join', channel: channel

leave = (channel, message) ->
	if not channel
		show '*** Please specify channel.'
	else
		channel = sanitize channel
		emit 'leave', channel: channel, message: message || "leaving"

names = (channel) ->
	if not channel
		show '*** Please specify channel.'
	else
		channel = sanitize channel
		emit 'names', channel: channel

whois = (nick) ->
	if not nick
		show '*** Please specify nick.'
	emit 'whois', nick: nick

list = ->
	emit 'list'

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
	show "*** /list - show channels"
	show "*** /say <message> - say on current channel."
	show "*** /join <channel> - join a channel. Alias: /j"
	show "*** /names [<channel>] - show who's on a channel"
	show "*** /next - next channel (shortcut: Ctrl-X)"
	show "*** /prev - previous channel"
	show "*** /whois [<nick>] - show info about a person"
	show "*** /leave [<channel>] [<message>] - leave a channel (current channel by default)"
#	show "*** /msg <nick> <message> - send private message to <nick>"
	show "*** /help - here we are. Alias: /h"
	show "*** /ping - ping the server."
	show "*** /reconnect - try to connect to the server if we're not connected."

say = (channel, msg) ->
	if not channel?
		show "*** You're not on a channel - try joining one. /list shows available channels."
	else
		channel = sanitize channel
		emit 'say', channel: channel, msg: msg

formatTime = (date) ->
	hours = String(date.getHours())
	mins = String(date.getMinutes())
	while hours.length < 2
		hours = '0' + hours
	while mins.length < 2
		mins = '0' + mins
	"#{hours}:#{mins}"

show = (msg, ts) ->
	ts ?= new Date().getTime()
	date = new Date(ts)
	time = formatTime(date)

	# probably close enough
	$('.chat').append "<p><time datetime='#{date.toISOString()}'>#{time}</time> #{escapeHtml msg}</p>"
	$('.chat').scrollTop 1000000

isCommand = (cmd) ->
	cmd.match /^\//

parseCommand = (cmd) ->
	[command, args...] = cmd.split /\s+/
	if command == '/'
		{ command: 'say', args: cmd.replace(/^\/\s+/, '') }
	else
		{ command: command.replace(/^\//, ''), args: args }

up = ->
	command = $('#cmd').val()
	if historyIdx == history.length
		newestCommand = command
	if --historyIdx < 0
		historyIdx = 0
	if historyIdx == history.length
		$('#cmd').val(newestCommand)
	else
		$('#cmd').val(history[historyIdx])
	$('#cmd')[0].setSelectionRange(10000, 10000)

down = ->
	command = $('#cmd').val()
	if historyIdx == history.length
		newestCommand = command
	if ++historyIdx > history.length
		historyIdx = history.length
	if historyIdx == history.length
		$('#cmd').val(newestCommand)
	else
		$('#cmd').val(history[historyIdx])
	$('#cmd')[0].setSelectionRange(10000, 10000)

execute = (cmd) ->
	if cmd.match /^\s*$/
		return

	history.push cmd
	historyIdx = history.length
	newestCommand = ''

#	console.log "history: #{JSON.stringify history}"

	if isCommand cmd
		{ command, args } = parseCommand cmd
	else
		{ command, args } = { command: 'say', args: cmd }

	switch command
		when 'nick' then newNick args[0]
		when 'ping' then ping()
		when 'join', 'j' then join args[0]
		when 'names', 'n' then names (args[0] ? mychannel)
		when 'whois', 'w' then whois (args[0] ? mynick)
		when 'list' then list()
		when 'say', 's' then say mychannel, args
		when 'help', 'h' then help args
		when 'reconnect', 're', 'reco' then reconnect()
		when 'leave', 'le', 'part' then leave(args[0] ? mychannel, args[1..].join ' ')
		when 'next' then next()
		when 'prev' then prev()
		else show "*** I don't know that command: #{command}."

initSocket = () ->
	protocol =
		disconnect: ->
			show "*** Disconnected from server."
			connected = false

		connect: ->
			show "*** Connected to server."
			connected = true
			ping()

		names: ({ channel, names }) ->
			names.sort()
			show "*** There are #{names.length} people on ##{channel}:"
			show "*** #{names.join ' '}"

		pong: (data) ->
			backThen = data.ts
			now = new Date().getTime()
			show "*** pong - roundtrip #{now - backThen} ms"

		channels: (data) ->
			channelNames = []
			for channel, idx in data.channels
				channelNames.push('#' + channel)
			if data.you
				channels = data.channels
				if channels.length
					setChannel channels[0]
				show "*** You're on channels: #{channelNames.join ' '}"
			else
				show "*** #{data.nick} is on channels: #{channelNames.join ' '}"

		nick: ({ oldNick, newNick, you }) ->
			info = { nick: { oldNick: oldNick, newNick: newNick } }
			if wasDuplicate(info)
				return

			if you?
				show "*** You are now known as #{newNick}."
				mynick = newNick
				$('.mynick').html(newNick)
			else
				show "*** #{oldNick} is now known as #{newNick}."

		error: (data) ->
			show "*** Failed to reconnect. Please try again later."

		info: ({ msg }) ->
			show "*** #{msg}"

		msg: ({ from, msg }) ->
			show "<#{from}> #{msg}"

		join: ({ nick, channel }) ->
			tellUser = true
			if nick == mynick
				setChannel(channel)
				if channel in channels
					tellUser = false
				else
					addChannel channel

			if tellUser
				show "*** #{nick} has joined channel ##{channel}."

		leave: ({ nick, channel, message }) ->
			show "*** #{nick} has left channel ##{channel} (#{message})."

			if nick == mynick
				nextChannel = removeChannel channel
				if mychannel == channel
					setChannel(nextChannel)

		say: ({ nick, channel, msg }) ->
			show "<#{nick}:##{channel}> #{msg}"
			# Some infos may be sent multiple times (for every channel you are on).
			# Ignore them. Should be done on the server side.
			previousInfo = null
			wasDuplicate = (info) ->
				if JSON.stringify(previousInfo) == JSON.stringify(info)
					#console.log "### Ignoring duplicate info #{JSON.stringify info}"
					true
				else
					previousInfo = info
					false

	for what, action of protocol
		do (what, action) ->
			log "Listening to #{what} with #{action}"
			socket.on what, (data) ->
				log "Got command #{what}"
				if debug
					if data?
						show "<= '#{what}': #{s data}"
					else
						show "<= '#{what}'"
				action data

	

$ ->
	mynick = $('.mynick').html()

	initSocket()

	focus = ->
		$('#cmd').focus()
	focus()

	clicks = 0
	timer = null

	$(window).click (e) ->
		clicks++
		if clicks == 1
			timer = setTimeout(->
				clicks = 0
				focus()
			,	300)
		else
			clearTimeout timer
			timer = setTimeout(->
				clicks = 0
			,	300)

	$(window).keypress (e) ->
		if e.target.id != 'cmd'
			$('#cmd').focus()
		# Ctrl-X
		if e.ctrlKey && e.keyCode == 24
			if e.shiftKey then prev() else next()
		# Ctrl-U
		if e.ctrlKey && e.keyCode == 21
			$('#cmd').val('')

	$('#cmd').keydown (event) ->
		if event.keyCode == 13
			cmd = $(event.target).val()
			execute(cmd)
			$(event.target).val('')
		if event.keyCode == 38
			up()
			event.preventDefault()
		if event.keyCode == 40
			down()
			event.preventDefault()

	$('#cmd').focus ->
		$('.input').addClass('focus')
	$('#cmd').blur ->
		$('.input').removeClass('focus')

	$('time').live 'click', (ev) ->
		show "*** That's #{new Date($(ev.target).attr('datetime'))}."

	initialChannels = (window.location.hash.replace /^#/, '').trim().split ','

	# TODO handling of these
	console.log "initials #{JSON.stringify initialChannels}"
#	for c in initialChannels
#		join c if c

	windowHeight = $(window).height()

	$(window).resize ->
		newHeight = $(window).height()
		if newHeight != windowHeight
			windowHeight = newHeight
			doLayout()

	doLayout = () ->
		magic = 76
		$('.chat').css('height', windowHeight - magic)
		$('body').css('height', windowHeight)

	doLayout()

