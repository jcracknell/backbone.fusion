$(function() {

	var bb = bb || { };
	bb.Collections = bb.Collections || { };
	bb.Models = bb.Models || { };
	bb.Views = bb.Views || { };

	bb.Models.TreeNode = Backbone.Model.extend({
		_children: undefined,

		defaults: function() {
			return {
				'name': '',
				'text': ''
			};
		},

		initialize: function() {

		}
	});

	bb.Collections.TreeNodeCollection = Backbone.Collection.extend({
		model: bb.Models.TreeNode,

		initialize: function() {
		}
	});

	bb.Views.TreeNodeView = Backbone.View.extend({
		model: bb.Models.TreeNode,
		_modelBinder: undefined,

		initialize: function() {
			this.setElement($($('#treenode-template').html())[0]);
			this._modelBinder = new Backbone.Fusion(this);
			this.model.set({toy: true});
		}
	});

	var rootNode = new bb.Models.TreeNode();
	var rootView = new bb.Views.TreeNodeView({ model: rootNode })
	$('body').append(rootView.el);
});
