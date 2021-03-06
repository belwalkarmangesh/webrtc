#
# Copyright (c) 2013, TNO, J. Abbink, K. Grigorjancs, J.P. Verdoorn
# All rights reserved.
#
#require.config
#	baseUrl: '../../../../../'

require [
	'library/models/token'
	], ( Token ) ->

	describe 'Token', ->

		token = null

		beforeEach ->
			token = new Token(1, 2)

		describe 'when constructed', ->

			it 'should have an id', ->
				expect(token.id).not.toBe(undefined)

			it 'should have a timestamp', ->
				expect(token.timestamp).not.toBe(undefined)

			it 'should have a candidates array', ->
				expect(token.candidates).not.toBe(undefined)

			it 'should have a higher or equal timestamp than id', ->
				expect(token.timestamp).not.toBeLessThan(token.id)

		describe 'when serialized', ->

			it 'should return a string', ->
				string = token.serialize()
				expect(typeof string).toBe('string')

			it 'should be able to be deserialized', ->
				string = token.serialize()
				newToken = Token.deserialize(string)
				expect(newToken instanceof Token).toBe(true)

			it 'should be equal to its deserialized serial', ->
				string = token.serialize()
				newToken = Token.deserialize(string)
				expect(newToken).toEqual(token)
