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
	describe '<textarea />', ->
		beforeEach ->
			element = document.createElement 'textarea'
		it 'should work', ->
			binding = new InputValueBinding element, 'description'
			binding.push description: 'This is some text.'
			expect(element.value).toEqual('This is some text.')
			expect(binding.pull()).toEqual(description: 'This is some text.')
		
