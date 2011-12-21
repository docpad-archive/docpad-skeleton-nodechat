# -------------------------------------
# Configuration

# Requires
docpad = require 'docpad'
express = require 'express'
io = require 'socket.io'
crypto = require 'crypto'

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

# ID Generation
userIds = {}
messageIds = {}
connectedUsers = {}
createId = (store) ->
	loop
		id = Math.random()+new Date().toString()
		id = crypto.createHash('md5').update(id).digest('hex')
		break  unless store[id]?
	id

# Start Server
docpadInstance.action 'server generate', ->
	# Server Ready

	# -------------------------------------
	# Sockets

	# IO
	io = io.listen(docpadServer)
	io.sockets.on 'connection', (socket) ->
		# Our user disconnected
		socket.on 'disconnect', ->
			socket.get 'user', (err,ourUser) ->
				throw err  if err
				delete connectedUsers[ourUser.id]
				socket.broadcast.emit 'user', 'delete', ourUser
	
		# User action
		socket.on 'user', (method, data, next) ->
			socket.get 'userId', (err,ourUserId) ->
				return next?(err)  if err
				console.log 'user', method, data.id, ourUserId
				if data.id is ourUserId
					socket.broadcast.emit 'user', method, data
					next?(null,data)
				else
					next? 'permission problem'

		# Message action
		socket.on 'message', (method, data, next) ->
			socket.get 'userId', (err,ourUserId) ->
				return next?(err)  if err
				console.log 'message', method, data.author.id, ourUserId
				if data.author.id is ourUserId
					data.id = createId(messageIds)  unless data.id
					socket.broadcast.emit 'message', method, data
					next?(null,data)
				else
					next? 'permission problem'
			
		# Handshake1: Generate and store the userId
		socket.on 'handshake1', (next) ->
			ourUserId = createId(userIds)
			socket.set 'userId', ourUserId, ->
				next? null, ourUserId
		
		# Handshake1: Store the user
		socket.on 'handshake2', (user,next) ->
			socket.set 'user', user, ->
				console.log connectedUsers
				next? null, connectedUsers
				connectedUsers[user.id] = user


# -------------------------------------
# Exports

module.exports = docpadServer