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
	extendServer: true

# Extract Logger
logger = docpadInstance.logger


# -------------------------------------
# Server Configuration

# DNS Servers
# masterServer.use express.vhost 'yourwebsite.*', docpadServer

# Start Server
# docpadInstance.action 'server'
docpadInstance.action 'server generate', ->

	# -------------------------------------
	# Server Extensions

	# IO
	io = io.listen(docpadServer)
	io.sockets.on 'connection', (socket) ->
		console.log 'connected'

		# Disconnect
		socket.on 'disconnect', ->
			console.log 'disconnected'

		# User
		docpadServer.all '/user', (req,res,next) ->
			console.log 'user', req.method, req.body
			# req.method
			# req.body
			if req.body and req.method
				if req.method in ['PUT','POST']
					socket.broadcast.emit "user", req.body
			res.contentType('json')
			res.send(success: true)

		# Message
		docpadServer.all '/message', (req,res,next) ->
			console.log 'message', req.method, req.body
			# req.method
			# req.body
			if req.body and req.method
				if req.method in ['PUT','POST']
					console.log 'sending message'
					socket.broadcast.emit "message", req.body
			res.contentType('json')
			res.send(success: true)

# IO Events
#socket.on "my other event", (data) ->
#	console.log data

# -------------------------------------
# Exports

module.exports = docpadServer