class Binder
	getValue: ->
		throw 'not implemented'
	setValue: ->
		throw 'not implemented'
	sources: (e) -> false

exports.ModelBinder = new Binder
