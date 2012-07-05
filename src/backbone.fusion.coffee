__namespace = exports ? window
__namespace = __namespace.Backbone or throw 'Include backbone.js before backbone.fusion.js'
__namespace = __namespace.Fusion = { }

# converts 'trueish' values to true and 'falsey' values to false
affirm = (expr) -> if expr then yes else no

Selector = do ->
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
	Create: (op, body) ->
		selector = { }
		selector[op] = body
		return selector
	Unpack: (selector) -> return [op, body] for op, body of selector
	# used to dynamically create a selector object
	InCanonicalForm: (selector) ->
		if _.isString(selector)	
			# 'string' -> { $seq: 'string' }
			return { $seq: selector }
		if _.isObject(selector)
			# { $op1: s1, $op2: s2 } -> { $all: [ { $op1: s1 }, { $op2: s2 } ] }
			selector = { $all: (Selector.Create opname, body for opname, body of selector) }
			if 1 is selector.$all.length
				# { $all: [ { $op: s } ] } -> { $op: s }
				selector = selector.$all[0]
			return selector
		return selector	
	Compile: (selector) ->
		[op, body] = Selector.Unpack Selector.InCanonicalForm selector
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

class Binding
	pull: -> throw 'not implemented'
	push: (attributes) -> throw 'not implemented'
	sources: (e) -> throw 'not implemented'

class Binder

	VERSION: "0.0.1"

	constructor: (view, config) ->
		throw 'You must pass in a view.' unless view

		@bindings = [] # Pull from config
		@config = config || {}
		@model = view.model
		@_bindViewToModel(@model)

	_bindViewToModel: -> @model.on 'change', @_onModelChange, this

	_unbindViewToModel: -> @model.off 'change', @_onModelChange, this
	
	_onModelChange: ->
		for attribute, value of @model.changedAttributes()
			for binding in @bindings
				binding.setValue @model.get(attribute) if binding.attribute is attribute and not binding.triggered

	_onElementChange: ->
		console.log "Fusion is aware that an el changed occurred."

# Attach an uninstantiated binder to the global Backbone object
__namespace.Selector = Selector
__namespace.Binder = Binder
