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
			socket.get 'userId', (err,ourUserId) ->
				throw err  if err
				# Exists
				if ourUserId
					# Get
					ourUser = store.users[ourUserId]
					# Delete
					socket.set 'userId', null, ->
						# Delete
						delete store.users[ourUserId]
						# Broadcast
						socket.broadcast.emit 'user', 'delete', ourUser
		
		# User action
		socket.on 'user', (method, data, next) ->
			socket.get 'userId', (err,ourUserId) ->
				return next?(err)  if err
				console.log 'user', method, data.id, ourUserId
				if data.id is ourUserId
					if  method is 'delete'
						# Error
						next? "you can't delete yourself"
					else
						# Apply
						store.users[ourUserId] = data
						# Broadcast
						socket.broadcast.emit 'user', method, data
						next?(null,data)
				else
					next? 'permission problem'

		# Message action
		# Retrieve our userId from our session
		# Compare it with the message author
		socket.on 'message', (method, data, next) ->
			socket.get 'userId', (err,ourUserId) ->
				return next?(err)  if err
				console.log 'message', method, data.author.id, ourUserId
				
				# Fetch
				ourMessage =
					if data.id
						store.messages[data.id] or null
					else
						null
				
				# Check
				switch method
					# Read
					when 'read'
						break
					
					# Delete
					when 'delete'
						if ourMessage
							if ourMessage.author.id is ourUserId
								delete store.messages[data.id]
								ourMessage = null
							else
								return next? 'access denied'
						else
							return next? 'not found'
						
						# Broadcast the changes
						socket.broadcast.emit 'message', method, ourMessage
					
					# Update, Create
					when 'update', 'create'
						# Update
						if data.id
							if ourMessage
								if ourMessage.author.id is ourUserId
									# Apply
									ourUser = store.users[ourUserId]
									data.author = ourUser
									ourMessage = store.messages[data.id] = data
								else
									return next? 'access denied'
							else
								return next? 'not found'
						
						# Create
						else
							# Apply
							data.id = createId(store.messages)  unless data.id
							ourUser = store.users[ourUserId]
							data.author = ourUser
							ourMessage = store.messages[data.id] = data
						
						# Broadcast the changes
						socket.broadcast.emit 'message', method, ourMessage
				
				# Success
				next?(null,ourMessage)
			
		# Handshake
		# Retrieve our userId from our session
		# If we don't have one, create one
		# If we do have one, use that, and fetch our user object
		# Send back ourUserId, ourUser, and store.users
		socket.on 'handshake', (next) ->
			# Get userId
			socket.get 'userId', (ourUserId) ->
				# Doesn't Exist
				unless ourUserId
					# Create
					ourUserId = createId(store.users)
					socket.set 'userId', ourUserId, ->
						# Broadcast
						next? null, ourUserId, null, store.users
				# Exists
				else
					# Fetch
					ourUser = store.users[ourUserId]
					# Broadcast
					next? null, ourUserId, ourUser or null, store.users


# -------------------------------------
# Exports

module.exports = docpadServer