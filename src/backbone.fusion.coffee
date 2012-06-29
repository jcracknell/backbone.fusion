root = exports ? window

class Binder
	constructor: (view, config) ->
		@bindings = []
		@config = 
		@model = view.model
		_bindViewToModel(@model)
	getValue: ->
		throw 'not implemented'
	setValue: ->
		throw 'not implemented'
	sources: (e) -> false

	_bindViewToModel = (model) ->
		model.on 'change', _onModelChange, this
	
	_onModelChange = ->
		console.log "Fusion is aware that a model changed occurred."

	_onElementChange = ->
		console.log "Fusion is aware that an el changed occurred."

# Attach an uninstantiated binder to the global Backbone object
root.Backbone.Fusion = Binder
