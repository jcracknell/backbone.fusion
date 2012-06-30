__namespace = exports ? window
__namespace = __namespace.Backbone or throw 'Include backbone.js before backbone.fusion.js'
__namespace = __namespace.Fusion = { }

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
__namespace.Binder = Binder
