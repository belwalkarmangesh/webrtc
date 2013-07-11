define [
	'public/models/remote._'

	'underscore'
	'adapter'
	], ( Remote, _ ) ->

	class Remote.Peer extends Remote

		type: 'peer'

		# Provides default server configuration for RTCPeerConnection.
		_serverConfiguration:
			iceServers: [
				url: 'stun:stun.l.google.com:19302'
				]

		# Provides default connection configuration for RTCPeerConnection. Note that 
		# 'RtpDataChannels: true' is mandatory for current Chrome (27).
		_connectionConfiguration:
			optional: [
				{ DtlsSrtpKeyAgreement: true }, 
				{ RtpDataChannels: true } 
				]

		# Provides default channel configuration for RTCDataChannel. Note that
		# 'reliable: false' is mandatory for current Chrome (27).
		_channelConfiguration:
			reliable: false

		# Initializes this class. Will attempt to connect to a remote peer through WebRTC.
		# Is called from the baseclass' constructor.
		#
		# @param _address [String] the address of the server to connect to
		#
		initialize: ( @id, connect = true ) ->
			@_connection = new RTCPeerConnection(@_serverConfiguration, @_connectionConfiguration)

			@_connection.onicecandidate = @_onIceCandidate
			@_connection.oniceconnectionstatechange = @_onIceConnectionStateChange
			@_connection.ondatachannel = @_onDataChannel

			@on('connect', @_onConnect)
			@on('disconnected', @_onDisconnected)
			@on('channel.opened', @_onChannelOpened)
			@on('channel.closed', @_onChannelClosed)

			if connect
				@connect()

		# Attempts to connect to the remote peer.
		#
		connect: ( ) ->
			@_isConnector = true
			@controller.emitTo(@id, 'peer.connectionRequest', @controller.id, @controller.type)

			channel = @_connection.createDataChannel('a', @_channelConfiguration)	
			@_connection.createOffer(@_onLocalDescription)

			@once('connect', =>	
				@_addChannel(channel)
			)

		# Disconnects from the peer.
		#
		disconnect: ( ) ->
			@_connection.close()

		# Returns wether or not this peer is connected.
		#
		# @return [Boolean] wether or not this peer is connected
		#
		isConnected: ( ) ->
			return @_connection.iceConnectionState is 'connected'

		# Sends a message to the remote.
		#
		# @param event [String] the event to send
		# @param args... [Any] any parameters you may want to pass
		#
		emit: ( event, args... ) ->
			unless @_channel?.readyState is 'open'
				return

			data = 
				name: event
				args: args

			@_channel.send(JSON.stringify(data))

		# Adds a new data channel, and adds event bindings to it.
		#
		# @param channel [RTCDataChannel] the channel to be added
		#
		_addChannel: ( channel ) ->
			@_channel = channel

			@_channel.onmessage = @_onChannelMessage
			@_channel.onopen = @_onChannelOpen
			@_channel.onclose = @_onChannelClose
			@_channel.onerror = @_onChannelError

		# Is called when a local description has been added. Will send this description
		# to the remote.
		#
		# @param description [RTCSessionDescription] the local session description
		#
		_onLocalDescription: ( description ) =>
			@_connection.setLocalDescription(description)
			@controller.emitTo(@id, 'peer.setRemoteDescription', @controller.id, description)

		# Is called when a remote description has been received. It will create an answer.
		#
		# @param id [String] a string representing the remote peer
		# @param description [Object] an object representing the remote session description
		#
		setRemoteDescription: ( description ) =>
			@_connection.setRemoteDescription(description)

			unless @_isConnector
				@_connection.createAnswer(@_onLocalDescription, null, {})

		# Provides a callback for adding ice candidates. When a candidate is present,
		# call candidate.add on the remote to add it.
		#
		# @param event [Event] the event thrown
		#
		_onIceCandidate: ( event ) =>
			if event.candidate?
				@controller.emitTo(@id, 'peer.addIceCandidate', @controller.id, event.candidate)

		# Is called when the remote wants to add an ice candidate.
		#
		# @param id [String] the id of the remote
		# @param candidate [Object] an object representing the ice candidate
		#
		addIceCandidate: ( candidate ) =>
			@_connection.addIceCandidate(candidate)

		# Is called when the ice connection state changed.
		#
		# @param event [Event] the connection change event
		#
		_onIceConnectionStateChange: ( event ) =>
			connectionState = @_connection.iceConnectionState

			switch connectionState
				when 'connected'
					@trigger('connect', @, event)
				when 'disconnected', 'failed', 'closed'
					@trigger('disconnected', @, event)

		# Is called when a data channel is added to the connection.
		#
		# @param event [Event] the data channel event
		#
		_onDataChannel: ( event ) =>
			@_addChannel(event.channel)

		# Is called when a data channel message is received.
		#
		# @param event [Event] the message event
		#
		_onChannelMessage: ( event ) =>
			data = JSON.parse(event.data)
			args = [data.name].concat(data.args)

			@trigger.apply(@, args)

		# Is called when the data channel is opened.
		#
		# @param event [Event] the channel open event
		#
		_onChannelOpen: ( event ) =>
			@_channelOpen = true

			@query( 'benchmark', ( benchmark ) =>
				@benchmark = benchmark
			)

			@query( 'system', ( system ) =>
				@system = system
			)

			@trigger('channel.opened', @, event)

		# Is called when the data channel is closed.
		#
		# @param event [Event] the channel close event
		#
		_onChannelClose: ( event ) =>
			@_channelOpen is false
			@trigger('channel.closed', @, event)

		# Is called when a connection has been established.
		#
		_onConnect: ( ) ->
			console.log "connected to node #{@id}"

		# Is called when a connection has been broken.
		#
		_onDisconnected: ( ) ->
			console.log "disconnected from node #{@id}"

		# Is called when the channel has opened.
		#
		_onChannelOpened: ( ) ->
			console.log "channel opened to node #{@id}"

		# Is called when the channel has closed.
		#
		_onChannelClosed: ( ) ->
			console.log "channel closed to node #{@id}"
