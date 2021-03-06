#
# Copyright (c) 2013, TNO, J. Abbink, K. Grigorjancs, J.P. Verdoorn
# All rights reserved.
#
define [], (  ) ->
	# Mock Express library
	class ExpressA
		constructor: ->
			@_getCallbacks = {}

			@get = jasmine.createSpy('get').andCallFake(( name, fn ) =>
					@_getCallbacks[name] = fn
				)
			@configure = jasmine.createSpy('configure').andCallFake(( callback ) ->
					callback()
				)
			@use = jasmine.createSpy('use')

	Express = ->
		new ExpressA()

	Express.static = jasmine.createSpy('static')

	Express
