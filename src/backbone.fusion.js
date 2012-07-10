// Backbone.Fusion.js
(function(_, $) {
	if(!$) throw 'Backbone.Fusion requires jQuery';
	if(!_) throw 'Backbone.Fusion requires underscore.js';

	var __module__ = (__module__ = typeof exports !== 'undefined' && exports !== null ? exports : window)
		&& (__module__ = __module__.Backbone || (function() { throw 'Backbone.Fusion requires Backbone.js'; })())
		&& (__module__ = __module__.Fusion = { });

	function kvp(k, v) {
		var p = { };
		p[k] = v;
		return p;
	}	

	var
		ArrayCheckboxInputBinding,
		Binder,
		Binding,
		BindingHelpers,
		BooleanCheckboxInputBinding,
		ElementBinding,
		TextInputBinding
	;	

	__module__.Binding = Binding = function() {
		this.read = function(model) { throw 'not implemented'; }
		this.write = function(model) { throw 'not implemented'; }
		this.sources = function(e) { throw 'not implemented'; }
	};

	__module__.ElementBinding = ElementBinding = function(element, configuration) {
		_.extend(this, new Binding());

		if(!_.isElement(element)) throw 'invalid element';
		if(null == configuration) throw 'null configuration';

		var _element = element;
		var _configuration = configuration;

		this.sources = function(e) {
			return _element === e.target && _.contains(_configuration.events, e.type);
		};
	};

	__module__.TextInputBinding = TextInputBinding = function(element, configuration) {
		_.extend(this, new ElementBinding(element, configuration));

		var _element = element;
		var _configuration = configuration;

		this.read = function(model) {
			return kvp(_configuration.attribute, _element.value);
		};

		this.write = function(model) {
			_element.value = model.get(_configuration.attribute);
		};
	};

	__module__.BooleanCheckboxInputBinding = BooleanCheckboxInputBinding = function(element, configuration) {
		_.extend(this, new ElementBinding(element, configuration));
		
		var _element = element;
		var _configuration = configuration;

		this.read = function(model) {
			return kvp(_configuration.attribute, _element.checked);
		};

		this.write = function(model) {
			_element.checked = !!model.get(_configuration.attribute);
		};
	};

	__module__.ArrayCheckboxInputBinding = ArrayCheckboxInputBinding = function(element, configuration) {
		_.extend(this, new ElementBinding(element, configuration));

		var _element = element;
		var _configuration = configuration;

		this.read = function(model) {
			var modelValue = model.get(_configuration.attribute);
			return _element.checked
				? kvp(_configuration.attribute, _.union(modelValue, [ _element.value ]))
				: kvp(_configuration.attribute, _.without(modelValue, _element.value));	
		};

		this.write = function(model) {
			_element.checked = _.contains(model.get(_configuration.attribute), _element.value);
		};
	};

	__module__.TemplateBinding = TemplateBinding = function(node) {
		_.extend(this, new Binding());
		if(null == node) throw 'unspecified node';

		var _node = node;
		var _template = _.template(_node.nodeValue, null, { interpolate: BindingHelpers.TEMPLATE_PATTERN });

		this.read = function(model) { throw 'unsupported operation'; };

		this.write = function(model) {
			_node.nodeValue = _template(model.toJSON());	
		};

		this.sources = function(e) { return false; };
	};

	__module__.BindingHelpers = BindingHelpers = (function() {
		var binders, getBindingConfiguration, isTemplatedNode;
		binders = [
			{
				bind: function(element, configuration) { return new TextInputBinding(element, configuration); },
				selector: function(element) {
					return _.isElement(element) && element.hasAttribute('data-binding')
						&& 'input' === element.tagName.toLowerCase()
						&& _.contains([ 'hidden', 'text', 'search', 'url', 'telephone', 'email', 'password', 'range', 'color' ], element.getAttribute('type'));
				}
			}, {	
				bind: function(element, configuration) { return new TextInputBinding(element, configuration); },
				selector: function(element) {
					return _.isElement(element) && element.hasAttribute('data-binding')
							&& 'textarea' === element.tagName.toLowerCase();
				}
			}, {
				bind: function(element, configuration) { return new BooleanCheckboxInputBinding(element, configuration); },
				selector: function(element) {
					return _.isElement(element) && element.hasAttribute('data-binding')
						&& 'input' === element.tagName.toLowerCase() && 'checkbox' === element.getAttribute('type')
						&& !element.hasAttribute('value');
				}
			}, {
				bind: function(element, configuration) { return new ArrayCheckboxInputBinding(element, configuration); },
				selector: function(element) {
					return _.isElement(element) && element.hasAttribute('data-binding')
						&& 'input' === element.tagName.toLowerCase() && 'checkbox' === element.getAttribute('type')
						&& element.hasAttribute('value');
				}
			}	
		];
		getBindingConfiguration = function(element) {
			if(!(_.isElement(element) && element.hasAttribute('data-binding')))
				return null;
			
			var attrValue, configuration;
			attrValue = element.getAttribute('data-binding');	
			if(!!~(attrValue.indexOf(':'))) {
				configuration = (function() {
					try { return eval('({' + attrValue + '})'); }
					catch (ex) { throw 'error evaluating binding configuration on element ' + element.outerHtml; }
				})();	
			} else {
				configuration = { attribute: attrValue };
			}

			configuration.events || (configuration.events = ['change']);

			return configuration;
		};

		isTemplatedNode = function(node) {
			return null != node.nodeValue && !!node.nodeValue.match(BindingHelpers.TEMPLATE_PATTERN);
		};

		return {

			TEMPLATE_PATTERN: /{{([a-zA-Z_$][a-zA-Z_$0-9]*)}}/g,

			DOM_EVENTS: [
				'change', 'focus', 'focusin', 'focusout', 'hover', 'keydown', 'keypress', 'keyup',
				'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseout', 'mouseover', 'mouseup',
				'resize', 'scroll', 'select', 'submit', 'toggle'
			],

			CreateBindingsForElement: function(element) {
				if(!_.isElement(element)) throw 'invalid element';

				var bindings = [ ];

				_.each(element.attributes, function(attributeNode) {
					if(isTemplatedNode(attributeNode))
						bindings.push(new TemplateBinding(attributeNode));
				});

				_.each(binders, function(binder) {
					if(!binder.selector(element)) return;
					
					var configuration = getBindingConfiguration(element);
					bindings.push(binder.bind(element, configuration));
				});

				var textNodes = _.filter(element.childNodes, function(n) { return Node.TEXT_NODE === n.nodeType; });
				_.each(textNodes, function(textNode) {
					if(isTemplatedNode(textNode))
						bindings.push(new TemplateBinding(textNode));
				});

				var childNodes = _.filter(element.childNodes, function(n) { return Node.ELEMENT_NODE === n.nodeType; });
				_.each(childNodes, function(child) {
					var childBindings = BindingHelpers.CreateBindingsForElement(child);
					_.each(childBindings, function(childBinding) {
						bindings.push(childBinding);
					});
				});

				return bindings;
			}
		};
	})();

	__module__.Binder = Binder = function() {
		var _bindings = [ ];
		var _model = null;
		var _element = null;
		var _sourceBinding = null;
		var _bound = false;

		function _onDomEvent(e) {
			if(null != _sourceBinding) throw 'concurrent events?';

			// Find the binding claiming responsibility for the event
			_sourceBinding = _.find(_bindings, function(binding) { return binding.sources(e); });

			// If no binding claimed the event, then do nothing
			if(null == _sourceBinding)
				return;

			_model.set(_sourceBinding.read(_model));	

			_sourceBinding = null;
		};

		function _onModelChange(e) {
			_.each(_bindings, function(binding) {
				if(_sourceBinding !== binding) {
					binding.write(_model);
				}
			});
		};

		this.bind = function bind(model, element) {
			if(!(null != model)) throw 'model must be specified';
			if(!_.isElement(element)) throw 'invalid element';
			if(_bound) throw 'Binder has already been bound';

			_bound = true;
			_model = model;
			_element = element;
			_bindings = BindingHelpers.CreateBindingsForElement(_element);

			_model.on('change', _onModelChange, this);
			$(_element).on(BindingHelpers.DOM_EVENTS.join(' '), _onDomEvent);

			_.each(_bindings, function(binding) {
				binding.write(_model);
			});
		};

		this.unbind = function unbind() {
			_model.off('change', _onModelChange, this);
			$(_element).off(BindingHelpers.DOM_EVENTS.join(' '), _onDomEvent);

			_bindings = [ ];
			_element = null;
			_model = null;
		};
	};
})(_, jQuery);