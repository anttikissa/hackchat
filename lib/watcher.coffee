fs = require 'fs'
{ log } = require './utils'
path = require 'path'

run = (dirs, cb) ->
	for dir in dirs
		files = fs.readdirSync dir
		matching = 0
		for file in files
			if file.match /\.coffee$/
				matching++
				filename = path.join dir, file
				fs.watch filename, (event, ignoredFilename) ->
					do (filename) ->
						cb filename
#		log.d "Watching changes in #{dir}/*.coffee [#{matching} file#{if matching != 1 then "s" else ""}]"

module.exports.run = run
