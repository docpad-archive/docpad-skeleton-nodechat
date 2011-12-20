# -------------------------------------
# Configuration

# Requires
docpad = require 'docpad'
express = require 'express'
io = require 'socket.io'

# Variables
oneDay = 86400000
expiresOffset = oneDay


# -------------------------------------
# DocPad Creation

# Configuration
docpadPort = process.env.DOCPADPORT || process.env.PORT || 10113

# Create Servers
docpadServer = express.createServer()

# Setup DocPad
docpadInstance = docpad.createInstance
	port: docpadPort
	maxAge: expiresOffset
	server: docpadServer
	plugins:
		admin: requireAuthentication: true
		rest: requireAuthentication: true

# Extract Logger
logger = docpadInstance.logger

# IO
io = io.listen(docpadServer)


# -------------------------------------
# Server Configuration

# DNS Servers
# masterServer.use express.vhost 'yourwebsite.*', docpadServer

# Start Server
# docpadInstance.action 'server'
docpadInstance.action 'server' # we need the generate for dynamic documents, if you don't utilise dynamic documents, then you just need the server


# -------------------------------------
# Server Extensions

# Place any custom routing here
# http://expressjs.com/

docpadServer.all '/message', (req,res) ->
	console.log 'asd'

io.sockets.on "connection", (socket) ->
	socket.emit "news", hello: "world"
	socket.on "my other event", (data) ->
		console.log data

# -------------------------------------
# Exports

module.exports = docpadServer