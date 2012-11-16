http = require './server/httpServer'
repl = require './server/repl'
watcher = require './lib/watcher'
{ log } = require './lib/utils'

log ''
log 'Server starting.'
log ''

http.run()
# repl.run()
watcher.run ['.', './lib', './server'], (which) ->
	log "File #{which} changed, restarting."
	setTimeout ->
		process.exit 2
	,	200

