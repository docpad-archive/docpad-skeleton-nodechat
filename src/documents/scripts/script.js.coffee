# Node Chat
# by Benjamin Lupton

# Globals
webkitNotifications = window.webkitNotifications
jQuery = window.jQuery
$ = window.$
Backbone = window.Backbone
_ = window._

# Locals
App =
	views: {}
	models: {}
	collections: {}


# =====================================
# Notifications

# Ensure Permissions
if webkitNotifications.checkPermission()
	$(document.body).click ->
		webkitNotifications.requestPermission()
		$(document.body).unbind()

# Setup helper
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

App.models.Base = Backbone.Model.extend
	_initialize: ->
		id = @get('id')
		unless id
			@set id: Math.random()
	
	initialize: ->
		@_initialize()


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
	defaults:
		username: null # [a-Z\.\-\_]
		email: null # email
		fullname: null # string
		avatar: null # url
	
	url: '/user'
	
	initialize: ->
		@_initialize()

		# Fetch values
		id = @get('id')
		email = @get('email')
		username = @get('username')

		# Ensure username
		unless username
			username = "User #{id}"
			@set username: username
		
		# Update Gravatar
		if email
			avatarSize = 80
			avatarHash = window.MD5(email)
			avatarUrl = "http://www.gravatar.com/avatar/#{avatarSize}.jpg?s=#{avatarSize}"
		else
			avatarUrl = null
		@set avatar: avatarUrl

		# Chain
		@


# -------------------------------------
# Message

App.models.Message = App.models.Base.extend
	defaults:
		posted: null # datetime
		content: null # string
		author: null # user
	
	url: '/message'

	initialize: ->
		# Super
		@_initialize()

		# Ensure POsted
		posted = @get('posted')
		if posted
			@set
				posted: new Date(posted)
		else
			@set
				posted: new Date()
		
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
		system = new App.models.User(
			username: 'system'
			email: 'b@lupton.cc'
		)
		socket = @options.socket
		user = new App.models.User()
		users =  new App.collections.Users()
		messages = new App.collections.Messages(
			new App.models.Message(
				author: system
				content: 'Welcome!'
			)
		)

		# Model
		@model.set
			system: system
			user: user
			users: users
			messages: messages

		# DomReady
		$ =>
			@render()
		
		# Chain
		@
	
	addUser: (data) ->
		#debugger
		console.log 'user:', data

		# Prepare
		users = @model.get('users')
		
		# Fetch
		user =
			if data.id
				users.get(data.id)
			else
				null
		
		# Apply
		if user
			user = user.set data
		else
			user = new App.models.User(data)
			users.add user
			Backbone.sync('create',user)
		
		# Return the user
		user
	
	addMessage: (data) ->
		#debugger
		console.log 'message:', data

		# Prepare
		messages = @model.get('messages')

		# Fetch
		message =
			if data.id
				messages.get(data.id)
			else
				null
		
		# Apply
		if message
			message = message.set data
		else
			data.author = @addUser(data.author)
			message = new App.models.Message(data)
			messages.add message
			Backbone.sync('create',message)
			if message.get('author').get('id') isnt @model.get('user').get('id')
				showNotification(
					title: message.get('author').get('username')+' says:'
					avatar: message.get('author').get('avatar')
					content: message.get('content')
				)

		# Return the message
		message
	
	render: ->
		# Values
		user = @model.get('user')
		messages = @model.get('messages')

		# Elements
		$editUserButton = @$('.editUserButton')
		$messages = @$('.messages.wrapper')
		$userForm = @$('.userForm.wrapper')
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

		# User Form
		@views.userForm = new App.views.UserForm(
			model: user
			container: $userForm
		).render().hide()


		# -----------------------------
		# Element Events
	
		# Edit User
		$editUserButton.click =>
			@views.userForm.show()
	
		# Send Message
		$messageInput.bind 'keypress', (event) =>
			if event.keyCode is 13 # enter
				event.preventDefault()
				message = $messageInput.val()
				@addMessage(
					author: user.toJSON()
					content: message
				)
				$messageInput.val('')
		
		# Chain
		@


# =====================================
# Application

# Prepare
$.timeago.settings.strings.seconds = "moments"
socket = io.connect('http://localhost:10113/')

# Start
app = new App.views.App(
	socket: socket
	container: $('#app')
	model: new App.models.App()
)
app.start()

# Sync
socket.on 'connect', ->
	console.log 'connected'
	socket.on "user", (data) =>
		console.log 'received user'
		#debugger
		app.addUser(data)
	socket.on "message", (data) =>
		console.log 'received message'
		#debugger
		app.addMessage(data)

# Expose
window.app = app
window.App = App