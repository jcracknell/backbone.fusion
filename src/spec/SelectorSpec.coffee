root = exports ? window

Selector = @Backbone.Fusion.Selector

selector = null
compiled = null

describe 'Backbone.Fusion.Selector', ->
	describe 'compilation', ->
		it 'should throw on invalid op', ->
			expect(-> Selector.Compile { $invalid: 'op' }).toThrow()
	describe '@attr op', ->
		describe 'compilation', ->
		describe 'execution', ->
			it 'should match an element with the correct attribute value', ->
				compiled = Selector.Compile { '@type': 'text' }
				element = document.createElement('input')
				element.setAttribute('type', 'text')
				expect(compiled(element)).toEqual(yes)
			it 'should not match an element with an incorrect attribute value', ->
				compiled = Selector.Compile { '@type': 'text' }
				element = document.createElement('input')
				element.setAttribute('type', 'hidden')
				expect(compiled(element)).toEqual(no)
			it 'should throw on non-dom candidate', ->
				compiled = Selector.Compile { '@type': 'date' }
				expect(-> compiled('not an element!')).toThrow('@type expects candidate dom element')
	describe 'string op', ->
		it 'should match the same string', ->
			compiled = Selector.Compile 'cat'
			expect(compiled('cat')).toEqual(yes)
		it 'should not match a different string', ->
			compiled = Selector.Compile 'dog'
			expect(compiled('cat')).toEqual(no)
	describe '$all op', ->		
		describe 'compilation', ->
			it 'should throw on null operand', ->
				expect(-> Selector.Compile { $all: null }).toThrow('$all expects array body')
		describe 'execution', ->
			describe 'of { $all: [ {$tag: \'input\'}, {\'@type\': \'text\'} ] }', ->
				beforeEach ->
					compiled = Selector.Compile { $all: [ {$tag: 'input'},  {'@type': 'text'} ] }
				it 'should match <input type="text"/>', ->
					element = document.createElement('input')
					element.setAttribute('type', 'text')
					expect(compiled(element)).toEqual(yes)
				it 'should not match <input type="hidden"/>', ->
					element = document.createElement('input')
					element.setAttribute('type', 'hidden')
					expect(compiled(element)).toEqual(no)
				it 'should not match <div type="text"/>', ->
					element = document.createElement('div')
					element.setAttribute('type', 'text')
					expect(compiled(element)).toEqual(no)
	describe '$any op', ->		
		describe 'compilation', ->
			it 'should throw on null operand', ->
				expect(-> Selector.Compile { $any: null }).toThrow('$any expects array body')
		describe 'execution', ->
			it 'should work', ->
				compiled = Selector.Compile { $any: [ 'cat', 'dog', 'baseball' ] }
				expect(compiled('cat')).toEqual(yes)
				expect(compiled('dog')).toEqual(yes)
				expect(compiled('baseball')).toEqual(yes)
				expect(compiled('no')).toEqual(no)
	describe '$defined op', ->		
		describe 'compilation', ->
			it 'should throw when not boolean', ->
				expect(-> Selector.Compile { $defined: 'hat' }).toThrow()
				expect(-> Selector.Compile { $defined: 1 }).toThrow()
				expect(-> Selector.Compile { $defined: 0 }).toThrow()
		describe 'when true', ->
			beforeEach ->
				compiled = Selector.Compile { $defined: yes }
			it 'should not match null', ->
				expect(compiled(null)).toEqual(no)
			it 'should not match undefined', ->
				expect(compiled(undefined)).toEqual(no)
			it 'should match anything else', ->
				expect(compiled('stringvalue')).toEqual(yes)
				expect(compiled('')).toEqual(yes)
				expect(compiled(false)).toEqual(yes)
				expect(compiled(0)).toEqual(yes)
		describe 'when false', ->
			beforeEach ->
				compiled = Selector.Compile { $defined: no }
			it 'should match null', ->
				expect(compiled(null)).toEqual(yes)
			it 'should match undefined', ->
				expect(compiled(null)).toEqual(yes)
			it 'should not match anything else', ->
				expect(compiled('stringvalue')).toEqual(no)
				expect(compiled('')).toEqual(no)
				expect(compiled(false)).toEqual(no)
				expect(compiled(0)).toEqual(no)
	describe '$matches op', ->		
		describe 'compilation', ->
			it 'should throw if not regex', ->
				expect(-> Selector.Compile { $matches: false }).toThrow()
		describe 'execution', ->
			it 'should work', ->
				compiled = Selector.Compile { $matches: /^\s+/ }
				expect(compiled(' ')).toEqual(yes)
				expect(compiled(' asdf')).toEqual(yes)
				expect(compiled('')).toEqual(no)
	describe '$tag op', ->
		describe 'compilation', ->
			it 'should throw on non-string operand', ->
				expect(-> Selector.Compile { $tag: 1 }).toThrow()
		describe 'execution', ->		
			beforeEach ->
				compiled = Selector.Compile { $tag: 'input' }
			it 'should match tag with correct tagName', ->
				expect(compiled(document.createElement('input'))).toEqual(yes)
			it 'should not match tag with incorrect tagName', ->
				expect(compiled(document.createElement('div'))).toEqual(no)
			it 'should throw on non-dom candidate', ->
				expect(-> compiled('bleargh')).toThrow('$tag expects candidate dom element')
