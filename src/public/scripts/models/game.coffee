define [
	'public/scripts/helpers/mixable'
	'public/scripts/helpers/mixin.eventbindings'

	'public/library/node.structured'
	
	'public/scripts/models/controller._'

	'public/scripts/models/world'
	'public/scripts/models/entity.player'

	'three'
	], ( Mixable, EventBindings, Node, Controller, World, Player, Three ) ->

	# This game class implements the node structure created in the library.
	# It uses three.js for the graphics.
	#
	class Game extends Mixable
		@concern EventBindings

		paused = true

		viewAngle = 45
		nearClip = 0.1
		farClip = 2000

		_lastUpdateTime = 0

		# This method will be called from the baseclass when it has been constructed.
		# 
		constructor: ( @scene ) ->
			# Create node and controller.
			@node = new Node()
			@controller = new Controller()

			# Create the world.
			@world = new World(@scene)

			# Listen to events.
			@node.server.once
				'connect': ( ) =>

			@node.on
				'joined': =>
					@node.off('joined')
					@trigger('joined')
				'left': =>
					console.log 'Left the network'

			@node.onReceive
				'player.list': ( list ) =>
					@world.createPlayer(id, false, info) for id, info in list
				'player.joined': ( id, info ) =>
					@world.createPlayer(id, false, info)
				'player.left': ( id ) =>
					@world.removePlayer(id)
				'player.died': ( id ) =>
					@world.removePlayer(id)
				'player.update': ( id, info, timestamp ) =>
					@world.applyPlayerInfo(id, info, timestamp)
				'player.fire': ( id, info, timestamp ) =>
					@world.createProjectile(info, timestamp)

		# Updates the phyics for all objects and renders the scene. Requests a new animation frame 
		# to repeat this methods.
		#
		# @param timestamp [Integer] the time that has elapsed since the first requestAnimationFrame
		#
		update: ( timestamp ) =>
			dt = (timestamp - @_lastUpdateTime) / 1000

			# Apply input to player.
			if @player?.loaded and not @paused
				@player.fire() if @controller.Fire
				@player.boost = @controller.Boost

				@player.flyLeft = @controller.FlyLeft
				@player.flyRight = @controller.FlyRight
				@player.flyForward = @controller.FlyForward
				@player.flyBackward = @controller.FlyBackward

				@player.cannon.rotateLeft = @controller.RotateCannonLeft
				@player.cannon.rotateRight = @controller.RotateCannonRight
				@player.cannon.rotateUpward = @controller.RotateCannonUpward
				@player.cannon.rotateDownward = @controller.RotateCannonDownward

			# Update the world
			@world.update(dt, @player)

			# Request a new animation frame.
			@_lastUpdateTime = timestamp

			return dt

		# Starts the game by finding a spawnpoint and spawning the player.
		#
		# @param position [Three.Vector3] the position override to spawn the player
		#
		startGame: ( position = null ) ->
			randomRadial = ( ) =>
				Math.random() * Math.PI * 2

			sanePosition = false
			while sanePosition is false
				radius = @world.planet.mesh.geometry.boundingSphere.radius
				euler = new Three.Euler(randomRadial(), randomRadial(), randomRadial())
				quaternion = new Three.Quaternion().setFromEuler(euler)

				position = new Three.Vector3(0, radius, 0)
				position.applyQuaternion(quaternion)

				if intersect = @world.planet.getIntersect(position, 4, radius)
					position = intersect.point
					sanePosition = true

			@createPlayer(position)
			@paused = false

		# Spawns the player in the world.
		#
		# @param position [Three.Vector3] the position at which to spawn the player
		#
		createPlayer: ( position ) =>
			if @player
				return

			@player = @world.createPlayer(@node.id, true, position: position.toArray())

			broadcastInterval = setInterval( ( ) =>
				@node.broadcast('player.update', @player.id, @player.getInfo())
			, 200)

			@player.on
				'fire': ( projectile ) =>
					@node.broadcast('player.fire', @player.id, projectile.getInfo())
				'die': ( ) =>
					@_onPlayerDied(broadcastInterval)

			@node.broadcast('player.joined', @player.id, @player.getInfo())

		# Is called when the player dies. Will cancel timed updates that are
		# broadcasted into the network.
		#
		# @param interval [Integer] the player broadcast interval to cancel.
		#
		_onPlayerDied: ( interval ) =>
			clearInterval(interval)
			@node.broadcast('player.died', @player.id)
			@player = null
			@trigger('player.died')

		# Returns the current network time.
		#
		# @return [Float] the network time
		#
		time: ( ) ->
			return @node.time()