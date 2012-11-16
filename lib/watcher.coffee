fs = require 'fs'
{ log } = require './utils'
path = require 'path'

run = (dirs, cb) ->
	for dir in dirs
		files = fs.readdirSync dir
		for file in files
			if file.match /\.coffee$/
				filename = path.join dir, file
				fs.watch filename, (event, ignoredFilename) ->
					do (filename) ->
						cb filename
		log.d "Watching changes in #{dir}/*.coffee [#{files.length} files]"

module.exports.run = run
