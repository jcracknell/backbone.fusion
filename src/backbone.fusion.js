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

function __extend(child, parent) {
	// This relies on _.each's use of the hasOwn test
	_.each(parent, function(value, key) { child[key] = value; });
	function ctor() { this.constructor = child; }
	ctor.prototype = parent.prototype;
	child.prototype = new ctor();
	return parent.prototype;
}

var
	ArrayCheckboxInputBinding,
	Binder,
	Binding,
	BindingHelpers,
	BooleanCheckboxInputBinding,
	BindingConfiguration,
	ElementBinding,
	Formats,
	FormattedElementBinding,
	TemplateBinding,
	TextInputBinding
;	

__module__.Formats = Formats = {
	'integer': function(value, context) {
		if(null === value || !/^-?[0-9]+$/.test(value = value.toString())) return NaN;
		return parseInt(value, 10);
	},
	'float': function(value, context) {
		if(null === value || !/^-?([0-9,]+(\.[0-9,]*)?)|(\.[0-9,]+)$/.test(value = value.toString())) return NaN;
		return parseFloat(value.replace(',', ''));
	},
	'money': function(value, context) {
		if('r' == context.direction) {
			if(null === value || !/^-?\$?([0-9,]+(\.[0-9]{0,2})?)|(\.[0-9]{1,2})$/.test(value = value.toString())) return NaN;
			return parseFloat(value.replace(/[^0-9.-]+/g, ''));
		} else {
			return null === value
				? ''
				: (value < 0 ? '-' : '') + '$' + value.toString();
		}
	},
	'negative-integer': function(value, context) {
		value = Formats['integer'](value, context);
		return value < 0 ? value : NaN;
	},
	'non-negative-integer': function(value, context) {
		value = Formats['integer'](value, context);
		return value >= 0 ? value : NaN;
	},
	'non-positive-integer': function(value, context) {
		value = Formats['integer'](value, context);
		return value <= 0 ? value : NaN;
	},
	'positive-integer': function(value, context) {
		value = Formats['integer'](value, context);
		return value > 0 ? value : NaN;
	},
	'text': function(value) {
		return (value || '').toString();
	}
};

__module__.BindingConfiguration = BindingConfiguration = (function() {

	function BindingConfiguration(defaults) {
		this._defaults = defaults || { };
		if(!_.isObject(this._defaults)) throw 'invalid defaults';
	}

	var ops = {
		$reset: function(param, target) {
			if(_.isArray(param)) {
				// { $reset: [ '@att1', '@att2' ] } -> reset defaults for multiple keys
				_.each(param, function(p) { target = ops.$reset(p, target); });
			} else if(_.isString(param)) {
				// { $reset: '@att' } -> reset defaults for specified key
				delete target[param];
			} else if(param) {
				// { $reset: true } -> reset all defaults
				target = { };	
			} else {
				throw 'invalid $reset param';
			}
			return target;
		}
	};

	function _isOperator(k) { return '$' === k.charAt(0); } 
	function _isAttribute(k) { return '@' === k.charAt(0); }
	function _isValue(k) { return !(_isAttribute(k) || _isOperator(k)); }

	function _applyOperators(target, source) {
		_.each(source, function(param, opName) {
			if(!_isOperator(opName)) return;
			var op = ops[opName];
			if(!op) throw 'invalid operator: ' + opName.toString();
			target = op(param, target);
		});
		return target;
	}

	function _applyValues(target, source) {
		_.each(source, function(value, key) {
			if(!_isValue(key)) return;

			if('format' === key && _.isString(value)) {
				var namedFormat = Formats[value];
				if(!namedFormat) throw 'invalid named format "' + value + '"';
				value = namedFormat;
			}

			target[key] = value;
		});
	}

	function _applyAttributes(target, source) {
		_.each(source, function(s, key) {
			if(!_isAttribute(key)) return;
			var t = target[key] || { };
			t = _applyOperators(t, s); 
			_applyValues(t, s);
			target[key] = t;
		});
	}

	function _apply(target, source) {
		target = _applyOperators(target, source);
		_applyAttributes(target, source);
		_applyValues(target, source);
		return target;
	};

	BindingConfiguration.prototype.raw = function() {
		return this._defaults;
	};

	BindingConfiguration.prototype.merge = function(other) {
		if(!_.isObject(other)) throw 'invalid other';

		var merged = { };
		merged = _apply(merged, this._defaults);
		merged = _apply(merged, other);

		return new BindingConfiguration(merged);
	};

	BindingConfiguration.prototype.get = function(attributeName) {
		if(!_.isString(attributeName)) throw 'invalid attributeName';
		
		var configuration = { };
		// Apply global defaults
		_applyValues(configuration, this._defaults);
		// Apply attribute-specific defaults
		var attributeConfiguration = this._defaults['@' + attributeName];
		if(attributeConfiguration)
			_applyValues(configuration, attributeConfiguration);

		return new BindingConfiguration(configuration);
	};

	return BindingConfiguration;
})();

__module__.Binding = Binding = (function() {
	function Binding() { } 
	Binding.prototype.read = function(model) { throw 'not implemented'; };
	Binding.prototype.write = function(model) { throw 'not implemented'; };
	Binding.prototype.sources = function(e) { throw 'not implemented'; };

	return Binding;
})();

__module__.ElementBinding = ElementBinding = (function() {
	var __super = __extend(ElementBinding, Binding);

	function ElementBinding(element, configuration) {
		__super.constructor.call(this);
		if(!_.isElement(element)) throw 'invalid element';
		if(null == configuration) throw 'null configuration';

		this._element = element;
		this._configuration = configuration;
		this._defaultEvents = ['change'];
	}

	ElementBinding.prototype.sources = function(e) {
		return e.target === this._element
			&& _.contains(this._configuration.events || this._defaultEvents, e.type);
	};

	return ElementBinding;
})();

__module__.FormattedElementBinding = FormattedElementBinding = (function() {
	var __super = __extend(FormattedElementBinding, ElementBinding);

	function FormattedElementBinding(element, configuration) {
		__super.constructor.call(this, element, configuration);
	}

	FormattedElementBinding.prototype._formatValue = function(value, model, direction) {
		if(!this._configuration.format) return value;

		return this._configuration.format(value, {
			binding: this,
			configuration: this._configuration,
			direction: direction,
			model: model,
		});
	};

	FormattedElementBinding.prototype._readRawValue = function() { throw 'not implemented'; };

	FormattedElementBinding.prototype.read = function(model) {
		var value = this._readRawValue();
		value = this._formatValue(value, model, 'r');
		return kvp(this._configuration.attribute, value);
	};

	FormattedElementBinding.prototype._writeRawValue = function(value) { throw 'not implemented'; };

	FormattedElementBinding.prototype.write = function(model) {
		var value = model.get(this._configuration.attribute);
		value = this._formatValue(value, model, 'w');
		this._writeRawValue(value);
	};

	return FormattedElementBinding;
})();

__module__.TextInputBinding = TextInputBinding = (function() {
	var __super = __extend(TextInputBinding, FormattedElementBinding);

	function TextInputBinding(element, configuration) {
		__super.constructor.call(this, element, configuration);
	}

	TextInputBinding.prototype._readRawValue = function() {
		return this._element.value;
	};

	TextInputBinding.prototype._writeRawValue = function(value) {
		this._element.value = value;
	};

	return TextInputBinding;
})();

__module__.BooleanCheckboxInputBinding = BooleanCheckboxInputBinding = (function() {
	var __super = __extend(BooleanCheckboxInputBinding, ElementBinding);

	function BooleanCheckboxInputBinding(element, configuration) {
		__super.constructor.call(this, element, configuration);
		if(!('checkbox' === element.getAttribute('type'))) throw 'invalid element';
	}
	
	BooleanCheckboxInputBinding.prototype.read = function(model) {
		return kvp(this._configuration.attribute, this._element.checked);
	};

	BooleanCheckboxInputBinding.prototype.write = function(model) {
		var value = model.get(this._configuration.attribute);
		// TODO: should this throw on non-boolean value?
		this._element.checked = !!value;
	};

	return BooleanCheckboxInputBinding;
})();

__module__.ArrayCheckboxInputBinding = ArrayCheckboxInputBinding = (function() {
	var __super = __extend(ArrayCheckboxInputBinding, ElementBinding);

	function ArrayCheckboxInputBinding(element, configuration) {
		__super.constructor.call(this, element, configuration);
		if(!('checkbox' === element.getAttribute('type'))) throw 'invalid element';
	}

	ArrayCheckboxInputBinding.prototype.read = function(model) {
		var modelValue = model.get(this._configuration.attribute);
		return this._element.checked
			? kvp(this._configuration.attribute, _.union(modelValue, [ this._element.value ]))
			: kvp(this._configuration.attribute, _.without(modelValue, this._element.value));	
	};

	ArrayCheckboxInputBinding.prototype.write = function(model) {
		this._element.checked = _.contains(model.get(this._configuration.attribute), this._element.value);
	};

	return ArrayCheckboxInputBinding;
})();

__module__.TemplateBinding = TemplateBinding = (function() {
	var __super = __extend(TemplateBinding, Binding);

	function TemplateBinding(node, defaultBindingConfigurations) {
		__super.constructor.call(this);
		if(null == node) throw 'unspecified node';
		if(!_.isObject(defaultBindingConfigurations)) throw 'invalid defaultBindingConfigurations';

		this._node = node;
		this._template = _.template(node.nodeValue, null, { interpolate: BindingHelpers.TEMPLATE_PATTERN });

		this._templateAttributes = { };
		var match;
		while(match = BindingHelpers.TEMPLATE_PATTERN.exec(node.nodeValue)) {
			var attributeName = match[1];
			this._templateAttributes[attributeName] = defaultBindingConfigurations['@' + attributeName] || { };
		}
	}

	TemplateBinding.prototype.read = function(model) { throw 'unsupported operation'; };

	TemplateBinding.prototype.write = function(model) {
		var templateValues = { };
		_.each(this._templateAttributes, function(configuration, attributeName) {
			var attributeValue = model.get(attributeName);
			if(configuration.format)
				attributeValue = configuration.format(attributeValue, { direction: 'w', model: model, configuration: configuration });

			templateValues[attributeName] = attributeValue;
		});

		this._node.nodeValue = this._template(templateValues);
	};

	TemplateBinding.prototype.sources = function(e) { return false; };

	return TemplateBinding;
})();

__module__.BindingHelpers = BindingHelpers = (function() {
	var BINDING_ATTRIBUTE = 'data-binding';
	var BINDING_DEFAULTS_ATTRIBUTE = 'data-binding-defaults';

	var binders = [
		{
			bind: function(element, configuration) { return new TextInputBinding(element, configuration); },
			binds: function(element) {
				return 'input' === element.tagName.toLowerCase()
					&& _.contains([ 'hidden', 'text', 'search', 'url', 'telephone', 'email', 'password', 'range', 'color' ], element.getAttribute('type'));
			}
		}, {	
			bind: function(element, configuration) { return new TextInputBinding(element, configuration); },
			binds: function(element) {
				return 'textarea' === element.tagName.toLowerCase();
			}
		}, {
			bind: function(element, configuration) { return new BooleanCheckboxInputBinding(element, configuration); },
			binds: function(element) {
				return 'input' === element.tagName.toLowerCase() && 'checkbox' === element.getAttribute('type')
					&& !element.hasAttribute('value');
			}
		}, {
			bind: function(element, configuration) { return new ArrayCheckboxInputBinding(element, configuration); },
			binds: function(element) {
				return 'input' === element.tagName.toLowerCase() && 'checkbox' === element.getAttribute('type')
					&& element.hasAttribute('value');
			}
		}	
	];

	function _getDeclaredConfigurationDefaults(element) {
		if(!element.hasAttribute(BINDING_DEFAULTS_ATTRIBUTE))
			return null;

		var declaredString = element.getAttribute(BINDING_DEFAULTS_ATTRIBUTE);
		return (function() {
			try { return eval('({' + declaredString + '})'); }
			catch (ex) { throw 'error evaluating ' + BINDING_DEFAULTS_ATTRIBUTE + ' "' + declaredString + '"'; }
		})();	
	}

	function _getDeclaredConfiguration(element) {
		if(!element.hasAttribute(BINDING_ATTRIBUTE))
			return null;

		var attributeValue = element.getAttribute(BINDING_ATTRIBUTE);
		if(!~attributeValue.indexOf(':'))
			return { attribute: attributeValue };
		
		return (function() {
			try { return eval('({' + attributeValue + '})'); }
			catch (ex) { throw 'error evaluating ' + BINDING_ATTRIBUTE + ' "' + attributeValue + '"'; }
		})();
	}

	var isTemplatedNode = function(node) {
		return null != node.nodeValue && !!node.nodeValue.match(BindingHelpers.TEMPLATE_PATTERN);
	};
	
	return {

		TEMPLATE_PATTERN: /{{([a-zA-Z_$][a-zA-Z_$0-9]*)}}/g,

		DOM_EVENTS: [
			'change', 'focus', 'focusin', 'focusout', 'hover', 'keydown', 'keypress', 'keyup',
			'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseout', 'mouseover', 'mouseup',
			'resize', 'scroll', 'select', 'submit', 'toggle'
		],

		CreateBindingsForElement: function(element, inheritedDefaults) {
			if(!_.isElement(element)) throw 'invalid element';

			var effectiveDefaults = (inheritedDefaults || new BindingConfiguration());
			var declaredDefaults = _getDeclaredConfigurationDefaults(element);
			if(declaredDefaults)
				effectiveDefaults = effectiveDefaults.merge(declaredDefaults);

			var declaredConfiguration = _getDeclaredConfiguration(element);
			if(declaredConfiguration) {
				var binder = _.find(binders, function(b) { return b.binds(element); });
				if(!binder) throw 'no binder binds element ' + element.tagName;

				var effectiveConfiguration = effectiveDefaults
					.get(declaredConfiguration.attribute)
					.merge(declaredConfiguration);

				return [ binder.bind(element, effectiveConfiguration.raw()) ];
			}

			var bindings = [ ];

			_.each(element.attributes, function(attributeNode) {
				if(isTemplatedNode(attributeNode))
					bindings.push(new TemplateBinding(attributeNode, effectiveDefaults.raw()));
			});

			_.each(element.childNodes, function(childNode) {
				switch(childNode.nodeType) {
					case Node.ELEMENT_NODE:
						_.chain(BindingHelpers.CreateBindingsForElement(childNode, effectiveDefaults))
							.each(function(childBinding) { bindings.push(childBinding); });
						break;
					case Node.TEXT_NODE:
						if(isTemplatedNode(childNode))
							bindings.push(new TemplateBinding(childNode, effectiveDefaults.raw()));
						break;
				}
			});

			return bindings;
		}
	};
})();

__module__.Binder = Binder = (function() {

	function Binder() {
		this._bindings = [ ];
		this._model = null;
		this._element = null;
		this._sourceBinding = null;
		this._bound = false;

		var _this = this;
		this._domEventHook = function(e) { return _this._onDomEvent(e); }
	}

	Binder.prototype._onDomEvent = function(e) {
		if(null != this._sourceBinding) throw 'concurrent events?';

		// Find the binding claiming responsibility for the event
		this._sourceBinding = _.find(this._bindings, function(binding) { return binding.sources(e); });

		// If no binding claimed the event, then do nothing
		if(null == this._sourceBinding)
			return;

		this._model.set(this._sourceBinding.read(this._model));	

		this._sourceBinding = null;
	};

	Binder.prototype._onModelChange = function(e) {
		_.each(this._bindings, function(binding) {
			if(this._sourceBinding !== binding) {
				binding.write(this._model);
			}
		}, this);
	};

	Binder.prototype.bind = function(model, element) {
		if(!(null != model)) throw 'model must be specified';
		if(!_.isElement(element)) throw 'invalid element';
		if(this._bound) throw 'Binder has already been bound';

		this._bound = true;
		this._model = model;
		this._element = element;
		this._bindings = BindingHelpers.CreateBindingsForElement(element);

		this._model.on('change', this._onModelChange, this);
		$(this._element).on(BindingHelpers.DOM_EVENTS.join(' '), this._domEventHook);

		_.each(this._bindings, function(binding) {
			binding.write(this._model);
		}, this);
	};

	Binder.prototype.unbind = function() {
		$(this._element).off(BindingHelpers.DOM_EVENTS.join(' '), this._domEventHook);
		this._model.off('change', this._onModelChange, this);

		this._bindings = [ ];
		this._element = null;
		this._model = null;
	};

	return Binder;
})();

})(_, jQuery);
