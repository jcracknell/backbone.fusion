__namespace = exports ? window
__namespace = __namespace.Backbone or throw 'Include backbone.js before backbone.fusion.js'
__namespace = __namespace.Fusion = { }

class Binding
	constructor: (@attribute, @el) ->
		if not @attribute? then throw 'must specify attribute'
		if not @el? then throw 'must specify el'
	getValue: -> throw 'not implemented'
	setValue: (value) -> throw 'not implemented'
	sources: (e) -> e.target is @el

class InputBinding extends Binding
	constructor: (@attribute, @el) ->
		super(@attribute, @el)
		if not @el.tagName.toLowerCase() in ['input', 'textarea'] then throw 'el must be input or textarea'
	getValue: ->
		@el.value
	setValue: (value) ->
		stringValue = value.toString()
		@el.value = stringValue

class Binder

	VERSION: "0.0.1"

	constructor: (view, config) ->
		throw 'You must pass in a view.' unless view

		@bindings = [] # Pull from config
		@config = config || {}
		@model = view.model
		@_bindViewToModel(@model)

	_bindViewToModel: -> @model.on 'change', @_onModelChange, this

	_unbindViewToModel: -> @model.off 'change', @_onModelChange, this
	
	_onModelChange: ->
		for attribute, value of @model.changedAttributes()
			for binding in @bindings
				binding.setValue @model.get(attribute) if binding.attribute is attribute and not binding.triggered

	_onElementChange: ->
		console.log "Fusion is aware that an el changed occurred."

# Attach an uninstantiated binder to the global Backbone object
__namespace.InputBinding = InputBinding
__namespace.Binder = Binder
