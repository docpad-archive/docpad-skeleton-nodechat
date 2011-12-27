# Node Chat (using DocPad)

Built using Socket.io, DocPad, Backbone.js and Twitter Bootstrap


## Play

1. [Install DocPad](https://github.com/balupton/docpad) 

1. Run

	``` bash
	git clone git://github.com/balupton/nodechat.docpad.git
	cd nodechat.docpad
	npm install
	node script.js [port]
	```

1. [Open http://localhost:10113/](http://localhost:10113/)


## Features

- Send and receive messages instantly (no sign-in required)
- [Markdown](http://daringfireball.net/projects/markdown/basics) support for messages
- User information updates are synced to everybody
- [Gravatars](http://gravatar.com) to see who you are chatting to
- Webkit chat notifications so you'll always notified
- See who's actively connected
- Times are all relative (e.g. '5 minutes ago')
- Supports reconnections


## Emphasis

Node Chat was built with the following emphasis

- It is a real-time, live-updating web application, as such the technology it uses should reflect that purpose
- It should be written to scale very easily
	- Utilised DocPad with modern markups to increase agility
	- Written with models to easily allow scaling of new and more complex fields and model requirements
		- No doubt the fields of `User` and `Message` will naturally change a lot over any course of time
- It should be written to support security
	- ID generation for the messages happen on the server-side
	- Broadcasts can only be sent by the user who created the item we are sending


## Technology

- Socket.io provides the client/server syncing and broadcasting ability
	- Used to sync user information
	- Used to broadcast new messages
- DocPad allows us to write our website in modern markups
	- Our HTML is written in CoffeeKup
	- Our CSS in Stylus
	- Our JavaScript in CoffeeScript
- Backbone.js provides our MVC infrastructure for the frontend
	- All the UI components are written as Backbone views providing greater modularity
		- Less side-effects
		- Greater re-usability
		- Easier to scale and sync
	- All the models are written as Backbone models and collections
		- Allows us to automaticly update views when a model changes
		- Allows us to easily sync models to the server
- Twitter Bootstrap provides our styling and design

These technologies work together really really well, as because a chat application is real-time (always having things changing, even without user interaction) we need a frontend implemetnation that is real-time too. Backbone.js and Socket.io fit perfectly for this, backbone.js provides the frontend infrastructure to provide a real-time / live-updating frontend interface, where socket.io provides the backend toolkit to sync the events. DocPad was a natural choice as it allows us to write our code in modern markups which greatly improves productivity, readability, and prevents errors.


## Todo / Known-issues

- Developer Documentation
- Autocomplete of people's names when you type `@` in the composer
- Notifications for when people are typing
- Notifications only when you are mentioned
- Better iPhone support
- Drag and drop files to the cloud support
- Private conversations support
- Multiple room support
- Private room support
- System commands. E.g. `/nick Your New Displayname`
- When people mouse over a username, they should get all the user details
- When people mouse over a relative time, they should get the absolute time
- Preselected color combinations instead of randomly generated


## License

Node Chat is developed by [Benjamin Lupton](http://balupton.com) and licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)