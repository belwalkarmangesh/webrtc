requirejs.config
	baseUrl: '../'

	shim:
		'jquery':
			exports: '$'

		'bootstrap': [ 'jquery' ]
		'jquery.plugins': [ 'jquery' ]

	# We want the following paths for 
	# code-sharing reasons. Now it doesn't 
	# matter from where we require a module.
	paths:
		'public': './'

		'jquery': 'vendor/scripts/jquery'
		'bootstrap': 'vendor/scripts/bootstrap'
		'canvas': 'vendor/scripts/ocanvas'
		
require [
	'scripts/app._'
	'library/node'
	'jquery'
	'canvas'
	], ( App, Node, $ ) ->

	# Mobile Controller Class
	#

	class App.Controller extends App
		
		# This method will be called from the baseclass when it has been constructed.
		# 
		initialize: ( ) ->
			@node = new Node()

			# Set canvas controls
			@boost = null
			@fire = null
			@poke = {}
			@pokeCanvas = null

			@drawControllers()


			@_lastBoost = false
			@_lastFire = false

			nodeId =  @getURLParameter("nodeId")
			@node.server.on('connect', ( ) =>
				@node.connect(nodeId)
			)
			@node._peers.on('channel.opened', ( ) =>

				@node.server.disconnect()
				@node.server = null

				# Send the device orientation 10 times a second
				if window.DeviceOrientationEvent
					setTimeout( @sendDeviceOrientation, 100)

				@boost.bind("touchstart", () => @sendBoostEvent(true))
				@boost.bind("touchend", () => @sendBoostEvent(false))
				@boost.bind("touchcancel", () => @sendBoostEvent(false))

				@fire.bind("touchenter", () => @sendFireEvent(true))
				@fire.bind("touchend", () => @sendFireEvent(false))
				@fire.bind("touchcancel", () => @sendFireEvent(false))
				
			)

			$(window).on('orientationchange resize', () =>
				@drawControllers()
			)
			
		drawControllers: () =>
			
			@canvas = oCanvas.create({
				canvas: "#canvas"
				disableScrolling : true
			})

			width = @canvas.width  = $(window).width()
			height = @canvas.height = $(window).height()

			if width > height

				@boost = @canvas.display.rectangle({
					x: width / 4,
					y: height / 2,
					origin: { x: "center", y: "center" },
					width: width /2,
					height: height,
					fill: "#0aa"
				})
				@fire = @canvas.display.rectangle({
					x: width * 3 / 4,
					y: height / 2,
					origin: { x: "center", y: "center" },
					width: width / 2,
					height: height,
					fill: "#f21"
				})

			else

				@boost = @canvas.display.rectangle({
					x: width / 2,
					y: height / 4,
					origin: { x: "center", y: "center" },
					width: width,
					height: height / 2,
					fill: "#0aa"
				})
				@fire = @canvas.display.rectangle({
					x: width / 2,
					y: height * 3 / 4,
					origin: { x: "center", y: "center" },
					width: width,
					height: height / 2,
					fill: "#f21"
				})

			boostText = @canvas.display.text({
				x: 0,
				y: 0,
				origin: { x: "center", y: "top" },
				font: "bold 25px/1.5 sans-serif",
				text: "Boost",
				fill: "#000"
			})

			@pokeCanvas = fireText = @canvas.display.ellipse({
				x: 0,
				y: 0,
				origin: { x: "center", y: "center" },
				font: "bold 25px/1.5 sans-serif",
				radius: 48,
				fill: "#000"
			})

			@canvas.addChild(@boost)
			@boost.addChild(boostText)

			@canvas.addChild(@fire)
			@fire.addChild(fireText)

			@fire.bind("touchenter", @initiatePoke, false )
			@fire.bind("touchmove", @handlePoke, false )
			@fire.bind("touchend", @stopPoke, false )
			@fire.bind("touchcancel", @stopPoke, false )

		initiatePoke: (event) =>
			console.log "start: ", event.x, event.y
			@poke.x = event.x
			@poke.y = event.y

		handlePoke: (event) =>
			sendPoke = {}
			sendPoke.x = event.x - @poke.x
			sendPoke.y = event.y - @poke.y
			console.log sendPoke
			@node.getPeers()[0].emit('controller.cannon', sendPoke)

			poke = {}
			poke.x = @fire.x - event.x
			poke.y = @fire.y - event.y
			@pokeCanvas.moveTo(-poke.x, -poke.y)
			@canvas.redraw()

		stopPoke: (event) =>
			@pokeCanvas.moveTo(0, 0)
			@canvas.redraw()
			
		# Get values stored in the url of the controller
		#
		# @param name [String] the name of the parameter
		# @return [String] the value of the parameter
		#
		getURLParameter: (name) ->
			results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(window.location.href)
			unless results?
				return null
			else
				return results[1] || 0

		# Send device orientation to the Game. Only available on mobile devices with support
		# of device orientation
		# 
		sendDeviceOrientation: ( ) =>
			window.addEventListener('deviceorientation', (eventData) =>
				@_roll = Math.round(eventData.gamma)
				@_pitch = Math.round(eventData.beta)

				orientation =
					roll: @_roll
					pitch: @_pitch

				@node.getPeers()[0].emit('controller.orientation', orientation)
			)

		# Send a boost event to the Game
		#
		# @param boost [Boolean] The incoming touchevent
		# 
		sendBoostEvent: ( boost ) ->
			if boost isnt @_lastBoost
				@_lastBoost = boost
				@node.getPeers()[0].emit('controller.boost', boost)

		# Send a fire event to the Game
		#
		# @param fire [Boolean] The incoming touchevent
		# 
		sendFireEvent: ( fire ) ->
			if fire isnt @_lastFire
				@_lastFire = fire
				@node.getPeers()[0].emit('controller.fire', fire)


	window.App = new App.Controller