require.config
	paths:
		'public': '../../public'
		'socket.io': '../mock/socket.io.mock'

require [
	'public/library/../library/models/remote.server'
	'public/library/models/message'
	'socket.io'

	], ( Server, Message, io ) ->

	describe 'Remote.Client', ->

		server = null
		fakeController = null

		class FakeController

			class FakeServer
				emitTo: ->
			
			constructor: ->		
				@server = new FakeServer()

			id: '2'
			query: ->
			relay: ->

		beforeEach ->
			fakeController = new FakeController()

		describe 'when initializing', ->
			it 'should start connecting', ->
				spyOn(Server.prototype, 'connect')
				server = new Server(fakeController, '127.0.0.1')

				expect(Server.prototype.connect).toHaveBeenCalled()

			it 'should start listening for the connect event', ->
				spyOn(Server.prototype, '_onConnect')
				server = new Server(fakeController, '127.0.0.1')

				server.trigger('connect')

				expect(Server.prototype._onConnect).toHaveBeenCalled()


		describe 'when connecting', ->
			it 'should make a new Socket.IO connection', ->
				spyOn(io, 'connect').andCallThrough()
				server = new Server(fakeController, '127.0.0.1')

				expect(io.connect).toHaveBeenCalled()
				expect(io.connect.mostRecentCall.args).toEqual([
						'127.0.0.1'
						 {
						 	'force new connection': true
						 }
					])

			it 'should start listening for message, connect and disconnect events on Socket.IO', ->
				called = []

				spyOn(io.prototype, 'on').andCallFake( ( query, fn ) ->
						called.push query
					)

				server = new Server(fakeController, '127.0.0.1')
				expect(called).toEqual([
						'message'
						'connect'
						'disconnect'
					])

		describe 'when disconnecting', ->
			it 'should disconnect the Socket.IO connection', ->
				server = new Server(fakeController, '127.0.0.1')

				spyOn(io.prototype, 'disconnect')

				server.disconnect()

				expect(io.prototype.disconnect).toHaveBeenCalled()

		describe 'when sending', ->
			it 'should relay the message to Socket.IO -> emit event', ->
				server = new Server(fakeController, '127.0.0.1')

				spyOn(io.prototype, 'emit')

				fakeMessage = new Message('a', 'b', 'event')
				server._send(fakeMessage)

				expect(io.prototype.emit).toHaveBeenCalled()
				expect(io.prototype.emit.mostRecentCall.args).toEqual([
						'message'
						fakeMessage.serialize()
					])

		describe 'when connecting', ->
			it 'should set own id to be Socket.IO session ID', ->
				server = new Server(fakeController, '127.0.0.1')

				server._onConnect()

				expect(fakeController.id).toBe('3')		# value from Mock Socket.IO