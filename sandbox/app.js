$(function() {

	var Sandbox = Sandbox || { };
	Sandbox.Collections = Sandbox.Collections || { };
	Sandbox.Models = Sandbox.Models || { };
	Sandbox.Views = Sandbox.Views || { };

	Sandbox.Models.Cat = Backbone.Model.extend({
		defaults: function() { return {
			'name': '',
			'age': 0,
			'description': ''
		} },
		initialize: function() {
		}
	});

	Sandbox.Views.CatView = Backbone.View.extend({
		model: Sandbox.Models.Cat,
		initialize: function() {
			this.setElement($($('#cat-template').html())[0]);
			this.binder = new Backbone.Fusion.Binder();
			this.binder.bind(this.model, this.el);
		}
	});

	var cat = new Sandbox.Models.Cat();
	cat.set({ name: 'Mr. Whiskers', description: 'lovely', age: 8 });
	var catView = new Sandbox.Views.CatView({ model: cat });
	$('body').append(catView.el);
});
