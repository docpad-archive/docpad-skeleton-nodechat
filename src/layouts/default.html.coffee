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
		text @blocks.scripts.join('')
		script src: 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.0/jquery.min.js'
		script src: 'http://cdnjs.cloudflare.com/ajax/libs/modernizr/2.0.6/modernizr.min.js'
		script src: 'scripts/script.js'