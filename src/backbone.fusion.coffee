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
				$tag: 'input'
				'@data-binding': $defined: yes
				'@type': $any: [ 'hidden', 'text', 'search', 'url', 'telephone', 'email', 'password', 'range', 'color' ]
			bind: (element) ->
				attribute = element.getAttribute('data-binding')
				return new InputValueBinding(element, attribute)
		}, {
			selector: Selector.Compile
				$tag: 'input'
				'@data-binding': $defined: yes
				'@type': 'checkbox'
			bind: (element) ->
				attribute = element.getAttribute('data-binding')
				return new CheckboxBinding(element)
		}
	]

	CreateBindingsForElement: (element) ->
		throw 'invalid element' unless element? and _.isElement(element)
		bindings = [ ]

		bindings.push binder.bind element for binder in binders when binder.selector element

		for child in element.children
			switch child.nodeType
				when Node.ELEMENT_NODE
					bindings.push binding for binding in BindingHelpers.CreateBindingsForElement child

		return bindings

__namespace.Binder = class Binder
	DOM_EVENTS = [ 'change', 'keyup' ]

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
		$(@_element).on DOM_EVENTS.join(' '), @_domEventHook

		b.push @_model.toJSON() for b in @_bindings 

	unbind: ->
		# We do not control dom events, so unhook the dom before the model
		$(@_element).off DOM_EVENTS.join(' '), @_domEventHook
		@_model.off 'change', @_onModelChange, this

		@_bindings = [ ]
		@_element = null
		@_model = null

	_onDomEvent: (e) ->
		throw '???' unless not @_sourceBinding?
		
		# Query the bindings to find one that claims responsibility for the event
		@_sourceBinding = do => return b for b in @_bindings when b.sources e
		if not @_sourceBinding?
			return

		@_model.set @_sourceBinding.pull()	

		@_sourceBinding = null

	_onModelChange: (e) ->
		b.push @_model.toJSON() for b in @_bindings when b isnt @_sourceBinding
