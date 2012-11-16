express = require 'express'
RedisStore = require('connect-redis')(express)

sessionStore = new RedisStore(host: 'nodejitsudb6214129596.redis.irstack.com', pass: 'nodejitsudb6214129596.redis.irstack.com:f327cfe980c971946e80b8e975fbebb4')
sessionStore.setMaxListeners(1024)

module.exports.sessionStore = sessionStore
