root = exports ? window

Backbone = @Backbone

describe 'Backbone.Fusion.Binder', ->
	it "Throws an error when initialized without a view", ->
		expect(-> new Backbone.Fusion.Binder).toThrow()
