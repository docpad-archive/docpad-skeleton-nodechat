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
docpadPort = process.argv[2]  or  process.env.DOCPADPORT  or  process.env.PORT  or  10113

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

# Store
store =
	users: {}
	messages: {}
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
				# Delete
				delete store.users[ourUser.id]
				# Broadcast
				socket.broadcast.emit 'user', 'delete', ourUser
	
		# User action
		socket.on 'user', (method, data, next) ->
			socket.get 'userId', (err,ourUserId) ->
				return next?(err)  if err
				console.log 'user', method, data.id, ourUserId
				if data.id is ourUserId
					if  method is 'delete'
						# Delete
						delete store.users[data.id]
					else
						# Apply
						store.users[data.id] = data
						# Broadcast
						socket.broadcast.emit 'user', method, data
						next?(null,data)
				else
					next? 'permission problem'

		# Message action
		socket.on 'message', (method, data, next) ->
			socket.get 'userId', (err,ourUserId) ->
				return next?(err)  if err
				console.log 'message', method, data.author.id, ourUserId
				# Check
				if data.author.id is ourUserId
					if  method is 'delete'  and  data.id
						# Delete
						delete store.messages[data.id]
					else
						# Apply
						data.id = createId(store.messages)  unless data.id
						store.messages[data.id] = data
						# Broadcast
						socket.broadcast.emit 'message', method, data
						next?(null,data)
				else
					# Problem
					next? 'permission problem'
			
		# Handshake1: Generate and store the userId
		socket.on 'handshake1', (next) ->
			# Apply
			ourUserId = createId(store.users)
			socket.set 'userId', ourUserId, ->
				# Broadcast
				next? null, ourUserId
		
		# Handshake1: Store the user
		socket.on 'handshake2', (user,next) ->
			socket.set 'user', user, ->
				# Apply
				store.users[user.id] = user
				# Broadcast
				next? null, store.users


# -------------------------------------
# Exports

module.exports = docpadServer