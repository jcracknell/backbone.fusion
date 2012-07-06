root = exports ? window

InputValueBinding = @Backbone.Fusion.InputValueBinding
BindingHelpers = @Backbone.Fusion.BindingHelpers

binding = null
element = null

describe 'Backbone.Fusion.InputValueBinding', ->
	describe '<input type="text"/>', ->
		beforeEach ->
			element = document.createElement('input')
			element.setAttribute('type', 'text')
		it 'should work', ->
			binding = new InputValueBinding(element, 'name')
			binding.push name: 'Mr. Whiskers'
			expect(element.value).toEqual('Mr. Whiskers')
	describe '<input type="password"/>', ->
		beforeEach ->
			element = document.createElement('input')
			element.setAttribute('type', 'password')
		it 'should work', ->
			binding = new InputValueBinding(element, 'password')
			binding.push password: 'unguessable'
			expect(element.value).toEqual('unguessable')
