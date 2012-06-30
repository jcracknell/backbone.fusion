root = exports ? window

InputBinding = @Backbone.Fusion.InputBinding

boundAttribute = null
boundElement = null
binding = null

describe 'Backbone.Fusion.InputBinding', ->
	beforeEach ->
		boundAttribute = 'name'
	describe 'when el is <input type="text"/>', ->
		beforeEach ->
			boundElement = document.createElement('input')
			boundElement.type = 'text'
			binding = new InputBinding(boundAttribute, boundElement)
		it 'should set value when setValue called', ->
			binding.setValue('Mr. Whiskers')
			expect(boundElement.value).toEqual('Mr. Whiskers')

