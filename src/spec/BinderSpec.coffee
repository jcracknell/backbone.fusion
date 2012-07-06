root = exports ? window

Binder = @Backbone.Fusion.Binder

binder = null
element = null
model = null

CatModel = @Backbone.Model.extend
	defaults:
		name: ''
		age: 0
		color: ''

describe 'Backbone.Fusion.Binder', ->
	beforeEach ->
		binder = new Binder()
		model = new CatModel()
	describe 'form element binding', ->
		describe '<input type="hidden"/>', ->
			beforeEach ->
				element = document.createElement 'input'
				element.setAttribute 'type', 'hidden'
				element.setAttribute 'data-binding', 'color'
				binder.bind model, element
			it 'should update the form element when the model changes', ->
				model.set color: 'orange'
				expect(element.value).toEqual('orange')
			it 'should update the model when the form element changes', ->
				element.value = 'orange'
				$(element).change()
				expect(model.get('color')).toEqual('orange')
		describe '<input type="text"/>', ->
			beforeEach ->
				element = document.createElement 'input'
				element.setAttribute 'type', 'text'
				element.setAttribute 'data-binding', 'name'
				binder.bind model, element
			it 'should update the form element when the model changes', ->	
				model.set name: 'Garfield'
				expect(element.value).toEqual('Garfield')
			it 'should update the model when the form element changes', ->	
				element.value = 'Nermal'
				$(element).change()
				expect(model.get('name')).toEqual('Nermal')
		describe '<input type="password"/>', ->
			beforeEach ->
				element = document.createElement 'input'
				element.setAttribute 'type', 'password'
				element.setAttribute 'data-binding', 'age'
				binder.bind model, element
			it 'should update the form element when the model changes', ->	
				model.set age: 12
				expect(element.value).toEqual('12')
			it 'should update the model when the form element changes', ->	
				element.value = '12'
				$(element).change()
				expect(model.get('age')).toEqual('12')
				
