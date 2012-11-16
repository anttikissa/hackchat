extras = /[TZ]/g

time = ->
	date = new Date()
	date.toISOString().replace extras, ' '

log = (msg) ->
	msg ?= ''
	console.log "#{time()}#{msg}"

log.d = (msg) ->
	msg ?= ''
	console.log "#{time()}[debug] #{msg}"

log.e = (msg) ->
	msg ?= ''
	console.err "#{time()}[ERROR] #{msg}"

s = -> JSON.stringify arguments...

module.exports.log = log
module.exports.s = s

