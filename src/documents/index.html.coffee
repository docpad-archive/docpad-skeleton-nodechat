---
title: 'Node Chat'
layout: 'default'
---

# =====================================
# Views

# Views
div "#views", ->

	# ---------------------------------
	# Application

	# App
	div ".app.view", ->
		header ".header.topbar", ->
			div ".fill", ->
				div ".container-fluid", ->
					h3 -> a -> "Node Chat"
					ul ".nav", ->
						li ".about", ->
							a -> 'About'
					ul ".nav.secondary-nav", ->
						li ".userStatus", ->
							span ".editUserButton.btn.primary", -> "Edit User"
		div ".body", ->
			div ".messages.wrapper", ->
			div ".users.wrapper", ->
			div ".messageForm", ->
				textarea ".messageInput", placeholder: "Your message..."
		div ".notificationList", ->
		div ".userForm.wrapper", ->
	
	# Notification
	div '.notification.view', ->
		div '.popover-wrapper', ->
			div '.popover.below', ->
				div '.arrow', ->
				div '.inner', ->
					h3 '.title', ->
					div '.content', ->
		
	
	# ---------------------------------
	# Users

	# User Form
	div ".userForm.view.modal", ->
		header ".header.modal-header", ->
			a ".close", -> 'x'
			h3 "Edit Details"
		div ".body.modal-body", ->
			input ".input.displayname.optional", type: 'text', placeholder: 'Display name'
			input ".input.email.optional", type: 'text', placeholder: 'Email'
		footer ".footer.modal-footer", ->
			button ".cancelButton.btn.secondary", -> "Cancel"
			button ".submitButton.btn.primary", -> "Update Details"

	# User
	div ".user.view", ->
		span ".id", ->
		span ".displayname", ->
		span ".email", ->
		span ".avatar", ->
			img ".avatarImage", ->

	# Users
	div ".users.view", ->
		table ".bordered-table.zebra-striped", ->
			thead ->
				tr ->
					th -> 'Users'
			tbody ".userList", ->


	# ---------------------------------
	# Messages

	# Message
	table ->
		tr ".message.view", ->
			td ".author.wrapper", ->
			td ".content", ->
			td ".posted", -> time datetime:"2008-02-14", -> 

	# Messages
	div ".messages.view", ->
		div ".page-header", ->
			h1 -> 'Messages'
		table ".bordered-table.zebra-striped", ->
			thead ->
				tr ->
					th ".author", -> 'User'
					th ".content", -> 'Message'
					th ".posted", -> 'Posted'
			tbody ".messageList", ->


# =====================================
# Application

# Application
div "#app", ->
