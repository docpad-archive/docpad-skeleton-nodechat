# Node Chat
# by Benjamin Lupton

# Globals
webkitNotifications = window.webkitNotifications or null
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

# Globals
randomFromTo = (from, to) ->
	Math.floor Math.random() * (to - from + 1) + from


# =====================================
# Notifications
# The code for google chrome notifications
# These are used for notifying the user of a new message
# They display an avatar, title and content

# Ensure Permissions
# If we don't have permissions, we will have to request them
if webkitNotifications and webkitNotifications.checkPermission()
	# Permissions can only be enabled from a user event
	# So do a dodgy hack to ensure they will be enabled
	# (when a user clicks anywhere of the page, we request the permissions)
	$(document.body).click ->
		webkitNotifications.requestPermission()
		$(document.body).unbind()

# Setup helper
# Provide a simpler API for our notifications
showNotification = ({title,content,avatar}) ->
	if webkitNotifications and webkitNotifications.checkPermission() is false
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
		color = @get('color')
		displayname = @get('displayname')

		# Ensure displayname
		unless displayname
			displayname = 'unknown'
			@set {displayname}
		@bind 'change:id', (model,id) =>
			displayname = @get('displayname')
			if displayname is 'unknown' or !displayname
				@set displayname: "User #{id}"
		
		# Ensure color
		unless color
			hue = randomFromTo(0,360)
			color = "hsl(#{hue}, 75%, 40%)"
			@set {color}
		
		# Ensure Gravatar
		@bind 'change:email', (model,email) =>
			if email
				avatarSize = 32
				avatarHash = MD5(email)
				avatarUrl = "http://www.gravatar.com/avatar/#{avatarHash}.jpg?s=#{avatarSize}"
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
		color: null # string
	
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
		@views[userKey].el.parent().parent().remove()
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
		color = @model.get('color')

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
			$('<img>').appendTo($avatar).attr('src',avatar).addClass('avatarImage')
		@el.css('color',color)

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
		if author.get('id') is 'system'
			$content.html(content)
		else
			@markdown or= new Showdown.converter()
			content = @markdown.makeHtml(content)
			content = window.html_sanitize(content)
			$content.html(content)
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
# Modal

App.views.Modal = App.views.Base.extend
	initialize: ->
		# Fetch
		@el = $('#views > .modal.view').clone().data('view',@)
		
		# Super
		@_initialize()
	
	populate: ->
		# Fetch
		title = @options.title
		content = @options.content
		buttons = @options.buttons or []

		# Elements
		$title = @$('.title')
		$content = @$('.content')
		$primary = @$('.primary')
		$footer = @$('.footer')

		# Populate
		$title.text(title or '').toggle(!!title)
		$content.text(content or '').toggle(!!content)

		# Events
		$footer.empty()
		for button in buttons
			$button = $('<button>').addClass('btn').text(button.text or 'Ok')
			$button.addClass('primary')  if button.primary
			$button.click  button.click  or  => @remove()
			$button.appendTo $footer

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
		
		# Bind
		_.bindAll @, 'onKeyPress', 'onNameChange', 'onResize'

		# Super
		@_initialize()
	
	start: ($container) ->
		# Prepare
		me = @
		socket = @options.socket
		disconnectedModal = null
		connectedOnce = false

		# Collections
		users = new App.collections.Users()
		messages = new App.collections.Messages()
		@model.set {users,messages}

		# Events
		users
			.bind 'add', (user) =>
				@user('add',user,false)
			.bind 'remove', (message) =>
				@user('remove',user,false)
		messages
			.bind 'add', (message) =>
				@message('add',message,false)
			.bind 'remove', (message) =>
				@message('remove',message,false)

		# Models
		system = @user 'create', {
			id: 'system'
			displayname: 'system'
			color: '#DAA520'
		}
		user = @user 'create', {}
		@model.set {system,user}
		
		# Handshake
		socket.on 'connect', =>
			# For now we do not support reconnections, so just refresh the entire page
			#if connectedOnce is true
			#	window.location.reload()
			#	return
			
			# If we do support reconnections, hide the disconnected modal if it exists
			if disconnectedModal
				disconnectedModal.remove()  
				disconnectedModal = null
			
			# Start our handshake
			# Retrieves _ourUserId (our user id), _ourUser (our user object, if cached), and _users (list of connected users)
			socket.emit 'handshake', (err,_ourUserId,_ourUser,_users) =>
				throw err  if err

				# Retrieved our user details
				if _ourUser
					# Apply them
					user.set _ourUser
				
				# Just retrieved a new id
				else
					# Apply it
					user.set id: _ourUserId
				
				# Save our user
				user.save()

				# Show the appropriate message dependening on whether this is a connection or reconnection
				if connectedOnce is true
					@systemMessage 'reconnected', {user}
				else
					connectedOnce = true
					@systemMessage 'welcome', {user}

				# Add the connected users to our application
				users.reset([system,user])
				for _userId, _user of _users
					@user 'add', _user
				
				# Finally, render our application when the DOM is ready
				$ => @render()

		# Disconnect
		socket.on 'disconnect', =>
			# We have been disconnected from the server, so let's show a modal prompting the user to refresh the browser
			disconnectedModal = new App.views.Modal(
				title: 'You have been disconnected'
				content: 'Try refreshing your browser'
				container: @el
				buttons: [
					{
						text: 'Refresh'
						primary: true
						click: ->
							window.location.reload()
					}
				]
			).render()
		
		# User
		socket.on 'user', (method,data) =>
			# We have received some changes to a user
			@user(method,data)
		
		# Message
		socket.on 'message', (method,data) =>
			# We have received some changes to a message
			@message(method,data)

		# Chain
		@
	
	# Render
	# Renders our application to the user
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
		@views.messages.remove()  if @views.messages
		@views.messages = new App.views.Messages(
			model: messages
			container: $messages.empty()
		).render()

		# Users
		@views.users.remove()  if @views.users
		@views.users = new App.views.Users(
			model: users
			container: $users.empty()
		).render()

		# User Form
		@views.userForm.remove()  if @views.userForm
		@views.userForm = new App.views.UserForm(
			model: user
			container: $userForm.empty()
		).render().hide().bind 'update', (user) ->
			user.save()
			notification = new App.views.Notification(
				title: 'Changes saved successfully'
				container: $notificationList
			).render()


		# -----------------------------
		# Element Events
	
		# Edit User
		$editUserButton.unbind().click =>
			@views.userForm.show()
		
		# Send Message
		$messageInput
			.unbind('keypress',@onKeyPress)
			.bind('keypress',@onKeyPress)
		
		# Focus
		$messageInput.focus()
		
		# Resize
		$(window)
			.unbind('resize',@onResize)
			.bind('resize',@onResize)
		@resize()

		# Chain
		@
	
	# Resize
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
	
	# onKeyPress
	onKeyPress: (event) ->
		# Prepare
		$messageInput = $(event.target)

		# Enter
		if event.keyCode is 13
			event.preventDefault()
			messageContent = $messageInput.val()
			$messageInput.val('')
			message = @message 'create', {
				author: @model.get('user')
				content: messageContent
			}
			message.save()
	
	# onResize
	onResize: (event) ->
		@resize()

	# onNameChange
	onNameChange: (model,userDisplayNameNew) ->
		user = model
		userDisplayNameOld = user.previous('displayname')
		@systemMessage 'nameChange', {
			user: user
			userDisplayNameOld: userDisplayNameOld
			userDisplayNameNew: userDisplayNameNew
		}

	# User
	# Performs an action against our user
	user: (method,data,applyToCollection) ->
		# Prepare
		me = @
		data or= {}
		users = @model.get('users')
		user = users.get(data.id)
		applyToCollection ?= true

		# HAndle
		switch method
			# Get
			when 'get'
				# Do nothing
				break
			
			# Delete
			when 'delete','remove'
				if user
					# Display the disconnected system message
					@systemMessage 'disconnected', {
						user: user
					}

					# Destroy the user
					# Remove it from our list of users
					# and return null
					users.remove(user.id)  if applyToCollection
					user = null
			
			# Update, Create
			when 'create','update','add'
				# Update
				if user
					# Update our user with the data
					# messages for this one are handled behind the scenes
					unless data instanceof App.models.User
						user.set(data)
				
				# Create
				else
					# Create the user with our passed data
					# and add it to our collection of users
					if data instanceof App.models.User
						user = data
					else
						user = new App.models.User()
					user.set data  if data
					users.add(user)  if applyToCollection
				
					# Subscribe to name changes so we can display the nameChange system message
					user
						.unbind('change:displayname',@onNameChange)
						.bind('change:displayname', @onNameChange)

					# Display the connected system message
					@systemMessage 'connected', {
						user: user
					}
		
		# Return user
		user
	

	# Message
	# Performs an action against our message
	message: (method,data,applyToCollection) ->
		# Prepare
		messages = @model.get('messages')
		message = messages.get(data.id)
		applyToCollection ?= true

		# Handle
		switch method
			# Get
			when 'get'
				# Do nothing
				break
			
			# Delete
			when 'delete','remove'
				if message
					# Destroy the message
					# Remove it from our list of messages
					# and return null
					messages.remove(data.id)  if applyToCollection
					message = null
			
			# Update, Create
			when 'create','update','add'
				# Update
				if message
					# Update our message with the data
					unless data instanceof App.models.Message
						message.set(data)
				
				# Create
				else
					# Create the message with our passed data
					# and add it to our collection of message
					if data instanceof App.models.Message
						message = data
					else
						message = new App.models.Message()
					message.set data  if data
					messages.add(message)  if applyToCollection
				
				# Added?
				if method is 'add'
					# Scroll
					@resize()

					# Notify
					@systemMessage 'newMessage', {message}
		
		# Return message
		message

	# systemMessage
	# Display a particular system message to the user
	systemMessage: (code,data) ->
		# Create
		switch code
			when 'newMessage'
				message = data.message
				messageAuthor = message.get('author')
				ourUser = @model.get('user')
				unless messageAuthor.get('id') in ['system',ourUser.get('id')]
					showNotification(
						title: messageAuthor.get('displayname')+' says:'
						avatar: messageAuthor.get('avatar')
						content: message.get('content')
					)
			
			when 'reconnected'
				user = data.user
				userColor = user.get('color')
				userDisplayName = user.get('displayname')
				ourUser = @model.get('user')
				@message 'create', {
					author: @model.get('system')
					content: "Welcome back <span style='color:#{userColor}'>#{userDisplayName}</span>"
				}
			
			when 'welcome'
				user = data.user
				userColor = user.get('color')
				userDisplayName = user.get('displayname')
				ourUser = @model.get('user')
				@message 'create', {
					author: @model.get('system')
					content: "Welcome <span style='color:#{userColor}'>#{userDisplayName}</span>"
				}
			
			when 'disconnected'
				user = data.user
				userColor = user.get('color')
				userDisplayName = user.get('displayname')
				ourUser = @model.get('user') or {}
				unless user.id in ['system',ourUser.id]
					@message 'create', {
						author: @model.get('system')
						content: "<span style='color:#{userColor}'>#{userDisplayName}</span> has disconnected"
					}
			
			when 'nameChange'
				user = data.user
				userColor = user.get('color')
				userDisplayNameOld = data.userDisplayNameOld
				userDisplayNameNew = data.userDisplayNameNew
				unless userDisplayNameOld is 'unknown'
					@message 'create', {
						author: @model.get('system')
						content: "<span style='color:#{userColor}'>#{userDisplayNameOld}</span> has changed their name to <span style='color:#{userColor}'>#{userDisplayNameNew}</span>"
					}
			
			when 'connected'
				user = data.user
				userColor = user.get('color')
				userDisplayName = user.get('displayname')
				ourUser = @model.get('user') or {}
				unless user.id in ['system',ourUser.id]
					@message 'create', {
						author: @model.get('system')
						content: "<span style='color:#{userColor}'>#{userDisplayName}</span> has joined"
					}
		
		# Chain
		@
	

# =====================================
# Application

# Prepare
$.timeago.settings.strings.seconds = "moments"
socket = io.connect document.location.href.replace /(\/\/.+)\/.*$/, '$1'

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