repl = require 'repl'

module.exports.run = ->
	repl.start
		prompt: '> '
		eval: (line, context, file, cb) ->
			line = line.replace(/(^\()|(\)$)/g, '').trim()
			[cmd, args...] = line.split /\s+/
			
			if cmd == 'q'
				process.exit 0

			if cmd == 'r'
				process.exit 2

			cb """
				Available commands:
				'q' - quit
				'r' - restart
			"""
