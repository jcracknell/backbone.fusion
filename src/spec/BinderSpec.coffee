root = exports ? window

Binder = @Backbone.Fusion.Binder

binder = null
element = null
model = null

CatModel = @Backbone.Model.extend
	defaults:
		declawed: no
		name: ''
		age: 0
		color: ''
		notes: ''
		features: ['striped']

describe 'Backbone.Fusion.Binder', ->
	beforeEach ->
		binder = new Binder()
		model = new CatModel()
	describe 'form element binding', ->
		describe '<input type="checkbox" />', ->
			beforeEach ->
				element = document.createElement 'input'
				element.setAttribute 'type', 'checkbox'
			describe 'with no value specified (boolean-valued)', ->	
				beforeEach ->
					element.setAttribute 'data-binding', 'declawed'
					binder.bind model, element
				it 'should update the form element when the model changes', ->
					expect(element.checked).toEqual(no)
					model.set declawed: yes
					expect(element.checked).toEqual(yes)
				it 'should update the model when the form element changes', ->
					expect(model.get('declawed')).toEqual(no)
					element.checked = true
					$(element).change()
					expect(model.get('declawed')).toEqual(yes)
			describe 'with value specified (array-valued)', ->		
				beforeEach ->
					element.setAttribute 'data-binding', 'features'
					element.setAttribute 'value', 'striped'
					binder.bind model, element
				it 'should update the form element when the model changes', ->
					expect(element.checked).toEqual(yes)
					model.set features: [ ]
					expect(element.checked).toEqual(no)
				it 'should update the model when the form element changes', ->
					expect(element.checked).toEqual(yes)
					element.checked = no
					$(element).change()
					expect(model.get('features').length).toEqual(0)
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
			it 'should update the form element when the model changes', ->	
				element.setAttribute 'data-binding', 'name'
				binder.bind model, element
				model.set name: 'Garfield'
				expect(element.value).toEqual('Garfield')
			it 'should update the model when the form element changes', ->	
				element.setAttribute 'data-binding', 'name'
				binder.bind model, element
				element.value = 'Nermal'
				$(element).change()
				expect(model.get('name')).toEqual('Nermal')
			it 'should update the model on specified events', ->
				element.setAttribute 'data-binding', "attribute: 'name', events: [ 'keypress' ]"
				binder.bind model, element
				element.value = 'Nermal'
				$(element).keypress()
				expect(model.get('name')).toEqual('Nermal')
			it 'should not update the model on unspecified events', ->
				element.setAttribute 'data-binding', "attribute: 'name', events: [ 'keypress' ]"
				binder.bind model, element
				element.value = 'Nermal'
				$(element).change()
				expect(model.get('name')).toEqual('')
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
		describe '<textarea/>', ->
			beforeEach ->
				element = document.createElement 'textarea'
				element.setAttribute 'data-binding', 'notes'
				binder.bind model, element
			it 'should update the form element when the model changes', ->	
				model.set notes: 'has no name'
				expect(element.value).toEqual('has no name')
			it 'should update the model when the form element changes', ->
				element.value = 'tends to shed'
				$(element).change()
				expect(model.get 'notes').toEqual('tends to shed')
