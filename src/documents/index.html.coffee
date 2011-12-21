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
				div ".container", ->
					h3 -> a -> "Node Chat"
					ul ".nav", ->
					ul ".nav.secondary-nav", ->
						li ".userStatus", ->
							span ".editUserButton.btn.primary", -> "Edit User"
		div ".body", ->
			div ".messages.wrapper", ->
			textarea ".messageInput", placeholder: "Your message..."
			div ".users.wrapper", ->
		div ".userForm.wrapper", ->


	
	# ---------------------------------
	# Users

	# User Form
	div ".userForm.view.modal", ->
		header ".header.modal-header", ->
			a ".close", -> 'x'
			h3 "Edit Details"
		div ".body.modal-body", ->
			input ".input.username.required", type: 'text', placeholder: 'Username'
			input ".input.email.optional", type: 'text', placeholder: 'Email'
			input ".input.fullname.optional", type: 'text', placeholder: 'Real name'
		footer ".footer.modal-footer", ->
			button ".cancelButton.btn.secondary", -> "Cancel"
			button ".submitButton.btn.primary", -> "Update Details"

	# User
	div ".user.view", ->
		span ".id", ->
		span ".username", ->
		span ".email", ->
		span ".fullname", ->
		img ".avatar", ->

	# Users
	div ".users.view", ->
		div ".userList", ->


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
