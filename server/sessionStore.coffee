express = require 'express'
RedisStore = require('connect-redis')(express)

sessionStore = new RedisStore()
sessionStore.setMaxListeners(1024)

module.exports.sessionStore = sessionStore
