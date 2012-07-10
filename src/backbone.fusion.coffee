__namespace = exports ? window
__namespace = __namespace.Backbone or throw 'Include backbone.js before backbone.fusion.js'
__namespace = __namespace.Fusion = { }

kvp = (k, v) ->
	p = { }
	p[k] = v
	return p

__namespace.Binding = class Binding
	read: (model) -> throw 'not implemented'
	write: (model) -> throw 'not implemented'
	sources: (e) -> throw 'not implemented'

__namespace.ElementBinding = class ElementBinding extends Binding
	constructor: (element, configuration) ->
		throw 'invalid element' unless _.isElement(element)
		throw 'null configuration' unless configuration?
		@_element = element
		@_configuration = configuration
	sources: (e) -> @_element is e.target	and e.type in @_configuration.events

__namespace.TextInputBinding = class TextInputBinding extends ElementBinding
	constructor: (element, configuration) -> 
		super element, configuration
	read: (model) -> kvp @_configuration.attribute, @_element.value
	write: (model) -> @_element.value = model.get(@_configuration.attribute)

__namespace.BooleanCheckboxInputBinding = class BooleanCheckboxInputBinding extends ElementBinding
	constructor: (element, configuration) -> 
		super element, configuration
		throw 'invalid element' unless _.isElement(element) and element.getAttribute('type') is 'checkbox' and not element.hasAttribute('value')
	read: (model) -> kvp @_configuration.attribute, @_element.checked
	write: (model) -> @_element.checked = !!model.get(@_configuration.attribute)

__namespace.ArrayCheckboxInputBinding = class ArrayCheckboxInputBinding extends ElementBinding
	constructor: (element, configuration) -> 
		super element, configuration
		throw 'invalid element' unless _.isElement(element) and element.getAttribute('type') is 'checkbox' and element.hasAttribute('value')
	read: (model) -> 
		modelValue = model.get(@_configuration.attribute)
		if @_element.checked
			return kvp @_configuration.attribute, _.union(modelValue, [@_element.value])	
		else
			return kvp @_configuration.attribute, _.without(modelValue, @_element.value)
	write: (model) ->
		@_element.checked = _.include model.get(@_configuration.attribute), @_element.value

__namespace.TemplateBinding = class TemplateBinding extends Binding
	constructor: (node) ->
		throw 'invalid node' unless node?
		@_node = node
		@_template = _.template(@_node.nodeValue, null, interpolate: BindingHelpers.TEMPLATE_PATTERN);
	read: (model) -> throw 'unsupported operation'
	write: (model) -> @_node.nodeValue = @_template(model.toJSON())
	sources: (e) -> no

__namespace.BindingHelpers = BindingHelpers = do ->
	binders = [
		{
			selector: (element) ->
				_.isElement(element) and element.hasAttribute('data-binding') \
				and ((
					element.tagName.toLowerCase() is 'input' \
					and element.getAttribute('type') in [ 'hidden', 'text', 'search', 'url', 'telephone', 'email', 'password', 'range', 'color' ]
				) or (
					element.tagName.toLowerCase() is 'textarea'
				))
			bind: (element, configuration) -> new TextInputBinding element, configuration
		}, {
			selector: (element) ->
				_.isElement(element) and element.hasAttribute('data-binding') \
				and element.tagName.toLowerCase() is 'input' and element.getAttribute('type') is 'checkbox' \
				and not element.hasAttribute('value')
			bind: (element, configuration) -> new BooleanCheckboxInputBinding element, configuration	
		}, {
			selector: (element) ->
				_.isElement(element) and element.hasAttribute('data-binding') \
				and element.tagName.toLowerCase() is 'input' and element.getAttribute('type') is 'checkbox' \
				and element.hasAttribute('value')
			bind: (element, configuration) -> new ArrayCheckboxInputBinding element, configuration	
		}	
	]
	getBindingConfiguration = (element) ->
		return null unless _.isElement(element) and element.hasAttribute('data-binding')

		attrValue = element.getAttribute 'data-binding'

		configuration = { }
		if attrValue.indexOf(':') > -1
			try
				configuration = eval "({#{attrValue}})"
			catch ex
				throw "error evaluating binding configuration on element #{element.innerHtml}"
		else
			configuration.attribute = attrValue

		configuration.events or= [ 'change' ]

		return configuration	

	isTemplatedNode = (node) -> node.nodeValue? and !!node.nodeValue.match(BindingHelpers.TEMPLATE_PATTERN)
	
	TEMPLATE_PATTERN: /{{([a-zA-Z_$][a-zA-Z_$0-9]*)}}/g

	DOM_EVENTS: [
		'change', 'focus', 'focusin', 'focusout', 'hover', 'keydown', 'keypress', 'keyup',
		'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseout', 'mouseover', 'mouseup',
		'resize', 'scroll', 'select', 'submit', 'toggle'
	]

	CreateBindingsForElement: (element) ->
		throw 'invalid element' unless element? and _.isElement(element)
		bindings = [ ]

		for attribute in element.attributes
			if isTemplatedNode(attribute)
				bindings.push new TemplateBinding attribute

		for binder in binders when binder.selector element
			configuration = getBindingConfiguration element
			bindings.push binder.bind element, configuration

		for child in element.childNodes
			switch child.nodeType
				when Node.ELEMENT_NODE
					bindings.push binding for binding in BindingHelpers.CreateBindingsForElement child
				when Node.TEXT_NODE
					if isTemplatedNode child
						bindings.push new TemplateBinding child

		return bindings

__namespace.Binder = class Binder

	constructor: ->
		@_bindings = [ ]
		@_model = null
		@_element = null
		@_sourceBinding = null
		@_bound = no

		# Create a function which explicitly calls the dom event handler
		# for this instance and is stored for event unhooking
		@_domEventHook = (e) => @_onDomEvent e
	
	bind: (model, element) ->
		throw 'model must be provided' unless model?
		throw 'element must be a dom element' unless _.isElement element

		throw 'Binder has already been bound' unless not @_bound
		@_bound = yes

		@_model = model
		@_element = element
		@_bindings = BindingHelpers.CreateBindingsForElement @_element

		# We do not control dom events, so hook up the model first
		@_model.on 'change', @_onModelChange, this
		$(@_element).on BindingHelpers.DOM_EVENTS.join(' '), @_domEventHook

		b.write(@_model) for b in @_bindings 

	unbind: ->
		# We do not control dom events, so unhook the dom before the model
		$(@_element).off BindingHelpers.DOM_EVENTS.join(' '), @_domEventHook
		@_model.off 'change', @_onModelChange, this

		@_bindings = [ ]
		@_element = null
		@_model = null

	_onDomEvent: (e) ->
		throw '???' unless not @_sourceBinding?
		
		# Query the bindings to find one that claims responsibility for the event
		@_sourceBinding = do => return b for b in @_bindings when b.sources e

		# If no binding sourced the event, then do nothing
		if not @_sourceBinding?
			return

		@_model.set @_sourceBinding.read(@_model)	

		@_sourceBinding = null

	_onModelChange: (e) ->
		b.write(@_model) for b in @_bindings when b isnt @_sourceBinding
