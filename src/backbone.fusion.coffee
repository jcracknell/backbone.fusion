__namespace = exports ? window
__namespace = __namespace.Backbone or throw 'Include backbone.js before backbone.fusion.js'
__namespace = __namespace.Fusion = { }

# converts 'trueish' values to true and 'falsey' values to false
affirm = (expr) -> if expr then yes else no

kvp = (k, v) ->
	p = { }
	p[k] = v
	return p

__namespace.Selector = Selector = do ->
	opCompilers = # selector operation definitions
		# { $all: [ s1, s2 ] } matches when s1 and s2 match
		$all: (body) ->
			throw '$all expects array body' unless _.isArray(body)
			compiledSelectors = (Selector.Compile s for s in body)
			return (candidate) ->
				return no for compiledSelector in compiledSelectors when not compiledSelector(candidate)
				return yes
		# { $any: [ s1, s2 ] } matches when s1 or s2 match		
		$any: (body) ->
			throw '$any expects array body' unless _.isArray(body)
			compiledSelectors = (Selector.Compile s for s in body)
			return (candidate) ->
				return yes for compiledSelector in compiledSelectors when compiledSelector(candidate)
				return no
		# { '@type': { $defined: 1 } } matches any element with defined type attribute
		$defined: (body) ->
			throw '$defined expects boolean body' unless body is yes or body is no
			return (candidate) -> if body then candidate? else not candidate?
		# { '@class': { $matches: /^\s+/ } } matches any element with class attribute starting with white space
		$matches: (body) ->
			throw '$matches expects regex body' unless _.isRegExp(body)
			return (candidate) ->
				throw '$matches expects candidate string' unless _.isString(candidate)
				return affirm candidate.match(body)
		$not: (body) ->
			compiled = Selector.Compile body
			return (candidate) -> not compiled(candidate)
		$seq: (body) ->
			throw '$seq expects string body' unless _.isString(body)
			return (candidate) -> affirm candidate? and candidate.toString() is body
		# { $tag: s1 } matches any element
		$tag: (body) ->
			compiledSelector = Selector.Compile body
			return (candidate) ->
				throw '$tag expects candidate dom element' unless _.isElement(candidate)
				return compiledSelector(candidate.tagName.toLowerCase())
	unpack = (selector) -> return [op, body] for op, body of selector
	canonicalForm = (selector) ->
		if _.isString(selector)	
			# 'string' -> { $seq: 'string' }
			return { $seq: selector }
		if _.isObject(selector)
			# { $op1: s1, $op2: s2 } -> { $all: [ { $op1: s1 }, { $op2: s2 } ] }
			selector = { $all: (kvp opname, body for opname, body of selector) }
			if 1 is selector.$all.length
				# { $all: [ { $op: s } ] } -> { $op: s }
				selector = selector.$all[0]
			return selector
		return selector	
	Compile: (selector) ->
		[op, body] = unpack canonicalForm selector
		if match = op.match(/^@([a-z][a-z-]*)$/)
			attributeName = match[1]
			compiledBody = Selector.Compile body
			return (candidate) ->
				throw "#{op} expects candidate dom element" unless _.isElement(candidate)
				return compiledBody candidate.getAttribute attributeName
		else
			opCompiler = opCompilers[op]
			throw "invalid selector operation #{op}" unless opCompiler?
			return opCompiler(body)

__namespace.Binding = class Binding
	pull: -> throw 'not implemented'
	push: (model) -> throw 'not implemented'
	sources: (e) -> throw 'not implemented'

__namespace.FilteringBinding = class FilteringBinding extends Binding	
	constructor: (filtered) ->
		throw 'filtered binding must be specified' unless filtered?
		@_filtered = filtered
	pull: -> @_filtered.pull()	
	push: (model) -> @_filtered.push(model)
	sources: (e) -> @_filtered.sources(e)

__namespace.EventFilteringBinding = class EventFilteringBinding extends FilteringBinding
	constructor: (filtered, events) ->
		super filtered
		throw 'events must be an array' unless _.isArray events
		@_events = events
	sources: (e) -> e.type in @_events and @_filtered.sources e

__namespace.InputValueBinding = class InputValueBinding extends Binding
	constructor: (@inputElement, @attribute) ->
		@inputElement.value = ''
	pull: -> kvp @attribute, @inputElement.value
	push: (model) -> @inputElement.value = model[@attribute]
	sources: (e) -> e.target is @inputElement	

__namespace.CheckboxBinding = class CheckboxBinding extends Binding	
	constructor: (@inputElement, @attribute) ->
	sources: (e) -> e.target is @inputElement	

__namespace.BindingHelpers = BindingHelpers = do ->
	binders = [
		{
			selector: Selector.Compile
				$any: [
					{
						$tag: 'input'
						'@data-binding': $defined: yes
						'@type': $any: [ 'hidden', 'text', 'search', 'url', 'telephone', 'email', 'password', 'range', 'color' ]
					}, {
						$tag: 'textarea'
						'@data-binding': $defined: yes
					}
				]	
			bind: (element, attribute) -> new InputValueBinding element, attribute
		}, {
			selector: Selector.Compile
				$tag: 'input'
				'@data-binding': $defined: yes
				'@type': 'checkbox'
			bind: (element, attribute) -> new CheckboxBinding(element, attribute)
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

	applyBindingConfiguration = (binding, configuration) ->
		throw 'binding configuration property events must be an array' unless _.isArray configuration.events
		throw "invalid binding configuration events event #{e}" for e in configuration.events when not _.include BindingHelpers.DOM_EVENTS, e
		binding = new EventFilteringBinding binding, configuration.events

		return binding
		
	DOM_EVENTS: [
		'change', 'focus', 'focusin', 'focusout', 'hover', 'keydown', 'keypress', 'keyup',
		'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseout', 'mouseover', 'mouseup',
		'resize', 'scroll', 'select', 'submit', 'toggle'
	]

	CreateBindingsForElement: (element) ->
		throw 'invalid element' unless element? and _.isElement(element)
		bindings = [ ]

		for binder in binders when binder.selector element
			configuration = getBindingConfiguration element
			binding = binder.bind element, configuration.attribute
			binding = applyBindingConfiguration binding, configuration
			bindings.push binding

		for child in element.children
			switch child.nodeType
				when Node.ELEMENT_NODE
					bindings.push binding for binding in BindingHelpers.CreateBindingsForElement child

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

		b.push @_model.toJSON() for b in @_bindings 

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

		@_model.set @_sourceBinding.pull()	

		@_sourceBinding = null

	_onModelChange: (e) ->
		b.push @_model.toJSON() for b in @_bindings when b isnt @_sourceBinding
