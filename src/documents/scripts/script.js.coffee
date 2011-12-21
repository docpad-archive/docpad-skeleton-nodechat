# Node Chat
# by Benjamin Lupton

# Globals
webkitNotifications = window.webkitNotifications
jQuery = window.jQuery
$ = window.$
Backbone = window.Backbone
_ = window._
MD5 = window.MD5

# Locals
App =
	views: {}
	models: {}
	collections: {}


# =====================================
# Notifications
# The code for google chrome notifications
# These are used for notifying the user of a new message
# They display an avatar, title and content

# Ensure Permissions
# If we don't have permissions, we will have to request them
if webkitNotifications.checkPermission()
	# Permissions can only be enabled from a user event
	# So do a dodgy hack to ensure they will be enabled
	# (when a user clicks anywhere of the page, we request the permissions)
	$(document.body).click ->
		webkitNotifications.requestPermission()
		$(document.body).unbind()

# Setup helper
# Provide a simpler API for our notifications
showNotification = ({title,content,avatar}) ->
	unless webkitNotifications.checkPermission()
		# Ensure
		avatar or= ""
		title or= "New message"
		content or= ""
		timer = null
		
		# Create and display notification
		notification = webkitNotifications.createNotification(avatar, title, content)
		notification.ondisplay = ->
			timer = setTimeout(->
				notification.cancel()
			, 5000)
		notification.onclose = ->
			if timer
				clearTimeout timer
				timer = null
		notification.show()


# =====================================
# Models

# -------------------------------------
# Base

App.models.Base = Backbone.Model.extend({})

# -------------------------------------
# App

App.models.App = App.models.Base.extend
	defaults:
		user: null # User Model
		users: null # User Collection
		messages: null # Messages Collection


# -------------------------------------
# User

App.models.User = App.models.Base.extend
	url: 'user'

	defaults:
		email: null # email
		displayname: null # string
		avatar: null # url
	
	initialize: ->
		# Fetch values
		cid = @cid
		username = @get('username')

		# Ensure username
		unless username
			username = 'unknown'
			@set {username}
		@bind 'change:id', (model,id) =>
			username = @get('username')
			if username is 'unknown' or !username
				@set username: "User #{id}"
		
		# Ensure Gravatar
		@bind 'change:email', (model,email) =>
			if email
				avatarSize = 80
				avatarHash = MD5(email)
				avatarUrl = "http://www.gravatar.com/avatar/#{avatarSize}.jpg?s=#{avatarSize}"
			else
				avatarUrl = null
			@set avatar: avatarUrl

		# Chain
		@


# -------------------------------------
# Message

App.models.Message = App.models.Base.extend
	url: 'message'

	defaults:
		posted: null # datetime
		content: null # string
		author: null # user
	
	initialize: ->
		# Fetch values
		posted = @get('posted')

		# Ensure Author
		@bind 'change:author', (model,author) ->
			if author
				unless author instanceof App.models.User
					@set author: new App.models.User(author)
		
		# Ensure Posted
		@bind 'change:posted', (model,posted) ->
			if posted
				unless posted instanceof Date
					@set posted: new Date(posted)
		@set posted: new Date()  unless posted
			
		# Chain
		@


# =====================================
# Collections

# -------------------------------------
# Base

App.collections.Base = Backbone.Collection.extend({})


# -------------------------------------
# Users

App.collections.Users = App.collections.Base.extend
	model: App.models.User


# -------------------------------------
# Messages

App.collections.Messages = App.collections.Base.extend
	model: App.models.Message


# =====================================
# Views

# -------------------------------------
# Base

App.views.Base = Backbone.View.extend
	_initialize: ->
		@views = {}
		if @el and @options.container
			@el.appendTo(@options.container)
		@
	
	initialize: ->
		@_initialize()
	


# -------------------------------------
# UserForm

App.views.UserForm = App.views.Base.extend
	initialize: ->
		# Fetch
		@el = $('#views > .userForm.view').clone().data('view',@)
	
		# Model Events
		@model.bind 'change', =>
			@populate()

		# Super
		@_initialize()
	
	populate: ->
		# Fetch
		id = @model.get('id')
		username = @model.get('username')
		email = @model.get('email')
		fullname = @model.get('fullname')

		# Populate
		$id = @$('.id').val(id)
		$username = @$('.username').val(username)
		$email = @$('.email').val(email)
		$fullname = @$('.fullname').val(fullname)

	render: ->
		# Populate
		@populate()

		# Elements
		$id = @$('.id')
		$username = @$('.username')
		$email = @$('.email')
		$fullname = @$('.fullname')
		$submitButton = @$('.submitButton')
		$cancelButton = @$('.cancelButton')
		$closeButton = @$('.close')

		# Events
		$submitButton.click =>
			@model.set
				username: $username.val()
				email: $email.val()
				fullname: $fullname.val()
			@hide()
			@trigger 'update', @model
		$cancelButton.add($closeButton).click =>
			@hide()
			@populate()
		
		# Chain
		@
	
	hide: ->
		@el.hide()
		@
	
	show: ->
		@el.show()
		@


# -------------------------------------
# Users

App.views.Users = App.views.Base.extend
	initialize: ->
		# Fetch
		@el = $('#views > .users.view').clone().data('view',@)
		
		# Model Events
		@model.bind 'add', (user) =>
			@addUser user
		@model.bind 'remove', (user) =>
			@removeUser user
		
		# Super
		@_initialize()
	
	addUser: (user) ->
		# Prepare
		$userList = @$('.userList')

		# User
		userId = user.get('id')
		userKey = "user-#{userId}"
		@views[userKey] = new App.views.User(
			model: user
			container: $userList
		).render()

		# Chain
		@
	
	removeUser: (user) ->
		# Prepare
		$userList = @$('.userList')

		# User
		userId = user.get('id')
		userKey = "user-#{userId}"
		@views[userKey].remove()

		# Chain
		@
	
	populate: ->
		# Prepare
		@views = {}
		users = @model
		$userLIst = @$('.userLIst').empty()

		# Messages
		users.each (user) =>
			@addUser(user)
		
		# Chain
		@
	
	render: ->
		# Prepare
		@populate()

		# Chain
		@

# -------------------------------------
# User

App.views.User = App.views.Base.extend
	initialize: ->
		# Fetch
		@el = $('#views > .user.view').clone().data('view',@)
		
		# Model Events
		@model.bind 'change', =>
			@populate()

		# Super
		@_initialize()
	
	populate: ->
		# Fetch
		id = @model.get('id')
		username = @model.get('username')
		email = @model.get('email')
		fullname = @model.get('fullname')
		avatar = @model.get('avatar')

		# Elements
		$id = @$('.id')
		$username = @$('.username')
		$email = @$('.email')
		$fullname = @$('.fullname')
		$avatar = @$('.avatar')

		# Populate
		$id.text(id or '').toggle(!!id)
		$username.text(username or '').toggle(!!username)
		$email.text(email or '').toggle(!!email)
		$fullname.text(fullname or '').toggle(!!fullname)
		$avatar.attr('src',avatar or '').toggle(!!avatar)
		
		# Chain
		@
	
	render: ->
		# Prepare
		@populate()

		# Chain
		@

# -------------------------------------
# Messages

App.views.Messages = App.views.Base.extend
	initialize: ->
		# Fetch
		@el = $('#views > .messages.view').clone().data('view',@)
		
		# Model Events
		@model.bind 'add', (message) =>
			@addMessage message
		
		# Super
		@_initialize()
	
	addMessage: (message) ->
		# Prepare
		$messageList = @$('.messageList')

		# Message
		messageId = message.get('id')
		messageKey = "message-#{messageId}"
		@views[messageKey] = new App.views.Message(
			model: message
			container: $messageList
		).render()

		# Chain
		@
	
	populate: ->
		# Prepare
		@views = {}
		messages = @model
		$messageList = @$('.messageList').empty()

		# Messages
		messages.each (message) =>
			@addMessage(message)
		
		# Chain
		@
	
	render: ->
		# Prepare
		@populate()

		# Chain
		@

# -------------------------------------
# Message

App.views.Message = App.views.Base.extend
	initialize: ->
		# Fetch
		@el = $('#views .message.view').clone().data('view',@)
		
		# Super
		@_initialize()
	
	populate: ->
		# Elements
		$id = @$('.id')
		$content = @$('.content')
		$posted = @$('.posted')
		$author = @$('.author.wrapper')

		# Get Values
		id = @model.get('id')
		posted = @model.get('posted')
		author = @model.get('author')
		content = @model.get('content')

		# Put Values
		$id.text(id)
		$content.text(content)
		$time = $("<time>").attr('datetime',posted.toUTCString()).appendTo($posted.empty()).timeago(posted)

		# Author
		@views.author = new App.views.User(
			model: author
			container: $author
		).render()

		# Chain
		@

	render: ->
		# Prepare
		@populate()

		# Chain
		@


# -------------------------------------
# App

App.views.App = App.views.Base.extend
	initialize: ->
		# Fetch
		@el = $('#views > .app.view').clone().data('view',@)
		
		# Super
		@_initialize()
	
	start: ($container) ->
		# Prepare
		me = @
		socket = @options.socket

		# Models
		system = new App.models.User(
			username: 'system'
			email: 'b@lupton.cc'
		)
		user = new App.models.User()
		users = new App.collections.Users()
		messages = new App.collections.Messages()
		@model.set {user,users,messages}
		
		# Events
		messages.bind 'add', (message) =>
			messageAuthor = message.get('author')
			return  if messageAuthor.get('id') is user.get('id')
			showNotification(
				title: messageAuthor.get('username')+' says:'
				avatar: messageAuthor.get('avatar')
				content: message.get('content')
			)

		# Handshake
		socket.on 'connect', =>
			socket.emit 'handshake1', (err,userId) ->
				throw err  if err
				user.set id: userId
				socket.emit 'handshake2', user, (err,_users) ->
					throw err  if err
					username = user.get('username')
					user.save()
					users.add(user)
					messages.add new App.models.Message(
						author: system
						content: "Welcome #{username}"
					)
					_.each _users, (_user) ->
						me.user 'add', _user
					$ => me.render()

		# User
		socket.on 'user', (method,data) =>
			@user(method,data)
		
		# Message
		socket.on 'message', (method,data) =>
			@message(method,data)

		# Chain
		@
	
	user: (method,data) ->
		users = @model.get('users')
		switch method
			when 'delete','remove'
				users.remove(data.id)
			when 'create','update','add'
				user = users.get(data.id)
				if user
					user.set(data)
				else
					user = new App.models.User()
					user.set data
					users.add(user)
		@
	
	message: (method,data) ->
		messages = @model.get('messages')
		switch method
			when 'delete','remove'
				messages.remove(data.id)
			when 'create','update','add'
				message = messages.get(data.id)
				if message
					message.set(data)
				else
					message = new App.models.Message()
					message.set data
					messages.add(message)
		@

	render: ->
		# Values
		user = @model.get('user')
		users = @model.get('users')
		messages = @model.get('messages')

		# Elements
		$editUserButton = @$('.editUserButton')
		$messages = @$('.messages.wrapper')
		$userForm = @$('.userForm.wrapper')
		$users = @$('.users.wrapper')
		$messageInput = @$('.messageInput')


		# -----------------------------
		# Views
	
		# Views
		@views = {}

		# Messages
		@views.messages = new App.views.Messages(
			model: messages
			container: $messages
		).render()

		# Users
		@views.users = new App.views.Users(
			model: users
			container: $users
		).render()

		# User Form
		@views.userForm = new App.views.UserForm(
			model: user
			container: $userForm
		).render().hide()


		# -----------------------------
		# Element Events
	
		# Edit User
		$editUserButton.click =>
			@views.userForm.show().bind 'update', (user) ->
				user.save()
	
		# Send Message
		$messageInput.bind 'keypress', (event) =>
			if event.keyCode is 13 # enter
				event.preventDefault()
				messageContent = $messageInput.val()
				$messageInput.val('')
				messages.create(
					author: user
					content: messageContent
				)
		
		# Chain
		@


# =====================================
# Application

# Prepare
$.timeago.settings.strings.seconds = "moments"
socket = io.connect('http://localhost:10113/')

# Sync
Backbone.sync = (method,model,options) ->
	data = model.toJSON()
	socket.emit model.url, method, data, (err,data) ->
		throw err  if err
		options.success?(data)

# Start
app = new App.views.App(
	socket: socket
	container: $('#app')
	model: new App.models.App()
)
app.start()

# Expose
window.app = app
window.App = App