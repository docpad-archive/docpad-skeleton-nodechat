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
		displayname = @get('displayname')

		# Ensure displayname
		unless displayname
			displayname = 'unknown'
			@set {displayname}
		@bind 'change:id', (model,id) =>
			displayname = @get('displayname')
			if displayname is 'unknown' or !displayname
				@set displayname: "User #{id}"
		
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
		displayname = @model.get('displayname')
		email = @model.get('email')

		# Populate
		$id = @$('.id').val(id)
		$displayname = @$('.displayname').val(displayname)
		$email = @$('.email').val(email)

	render: ->
		# Populate
		@populate()

		# Elements
		$id = @$('.id')
		$displayname = @$('.displayname')
		$email = @$('.email')
		$submitButton = @$('.submitButton')
		$cancelButton = @$('.cancelButton')
		$closeButton = @$('.close')

		# Events
		$displayname.add($email).keypress (event) =>
			if event.keyCode is 13 #enter
				event.preventDefault()
				$submitButton.trigger('click')
		$submitButton.click =>
			@model.set
				displayname: $displayname.val()
				email: $email.val()
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
		$displayname = @$('.displayname')
		$displayname.focus()
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
			container: $('<tr><td class="user wrapper"></tr>').appendTo($userList).find('.user.wrapper')
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
		$userList = @$('.userList').empty()

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
		displayname = @model.get('displayname')
		email = @model.get('email')
		avatar = @model.get('avatar')

		# Elements
		$id = @$('.id')
		$email = @$('.email')
		$displayname = @$('.displayname')
		$avatar = @$('.avatar')

		# Populate
		$id.text(id or '')
		$displayname.text(displayname or '')
		$email.text(email or '')
		$avatar.empty()
		if avatar
			$('<img class="avatarImage">').appendTo($avatar).attr('src')
		
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
# Notification

App.views.Notification = App.views.Base.extend
	initialize: ->
		# Fetch
		@el = $('#views > .notification.view').clone().data('view',@)
		
		# Super
		@_initialize()
	
	populate: ->
		# Fetch
		title = @options.title
		content = @options.content

		# Elements
		$title = @$('.title')
		$content = @$('.content')

		# Populate
		$title.text(title or '').toggle(!!title)
		$content.text(content or '').toggle(!!content)

		# Chain
		@

	render: ->
		# Prepare
		@populate()

		# Display
		if @_timeout
			clearTimeout(@_timeout)
			@_timeout = null
		@el.stop(true,true).hide().fadeIn 200, =>
			@_timeout = setTimeout(=>
				@el.fadeOut 200, =>
					unless @options.destroy? and @options.destroy is false
						@remove()
			,2000)

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
	
	resize: ->
		$window = $(window)
		$header = @$('.header.topbar')
		$messagesWrapper = @$('.messages.wrapper')
		$messagesView = $messagesWrapper.find('.messages.view')
		$usersWrapper = @$('.users.wrapper')
		$messageForm = @$('.messageForm')

		$usersWrapper.height  $window.height()
		$messagesWrapper.width  $window.width() - $usersWrapper.outerWidth()
		$messageForm.width  $window.width() - $usersWrapper.outerWidth()
		$messagesWrapper.height  $window.height() - $messageForm.outerHeight() - $header.outerHeight()

		setTimeout(=>
			$messagesWrapper.prop 'scrollTop', $messagesView.outerHeight()
		,100)
	
	start: ($container) ->
		# Prepare
		me = @
		socket = @options.socket

		# Models
		system = new App.models.User(
			displayname: 'system'
			email: 'nodechat@bevry.me'
		)
		user = new App.models.User()
		users = new App.collections.Users()
		messages = new App.collections.Messages()
		@model.set {user,users,messages}
		
		# Events
		messages.bind 'add', (message) =>
			# Scroll
			@resize()

			# Notify
			messageAuthor = message.get('author')
			return  if messageAuthor.get('id') is user.get('id')
			showNotification(
				title: messageAuthor.get('displayname')+' says:'
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
					displayname = user.get('displayname')
					user.save()
					users.add(user)
					messages.add new App.models.Message(
						author: system
						content: "Welcome #{displayname}"
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
		$notificationList = @$('.notificationList')


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
		).render().hide().bind 'update', (user) ->
			user.save()
			notification = new App.views.Notification(
				title: 'Changes saved successfully'
				container: $notificationList
			).render()


		# -----------------------------
		# Element Events
	
		# Edit User
		$editUserButton.click =>
			@views.userForm.show()
		
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
		
		# Focus
		$messageInput.focus()
		
		# Resize
		@resize()

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