root = exports ? window

Backbone = @Backbone

describe "Backbone.Fusion", ->
	it "Throws an error when initialized without a view", ->
		initializeFusion = ->
			fusion = new Backbone.Fusion

		expect(initializeFusion).toThrow()
