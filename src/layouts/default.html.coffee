---
title: 'Blank Canvas'
---

doctype 5
html lang: 'en', ->
	head ->
		# Standard
		meta charset: 'utf-8'
		meta 'http-equiv': 'X-UA-Compatible', content: 'IE=edge,chrome=1'
		meta 'http-equiv': 'content-type', content: 'text/html; charset=utf-8'
		meta name: 'viewport', content: 'width=device-width, initial-scale=1'

		# Document
		title @document.title
		meta name: 'description', content: @document.description or ''
		meta name: 'author', content: @document.author or ''

		# Styles
		link rel: 'stylesheet', href: '/styles/style.css', media: 'screen, projection'
		link rel: 'stylesheet', href: '/styles/print.css', media: 'print'
		text @blocks.styles.join('')
	body ->
		# Document
		text @content

		# Scripts
		script src: '/vendor/jquery-1.7.1.min.js'
		script src: '/vendor/modernizr-2.0.6.min.js'
		script src: '/vendor/underscore-1.2.2.min.js'
		script src: '/vendor/backbone-0.5.3.js'
		#script src: '/vendor/xdate-0.5.min.js'
		#script src: '/vendor/bootstrap/js/bootstrap-modal.js'
		script src: '/vendor/webtoolkit.md5.js'
		script src: '/vendor/jquery.timeago.js'
		script src: '/socket.io/socket.io.js'
		script src: '/scripts/script.js'
		text @blocks.scripts.join('')