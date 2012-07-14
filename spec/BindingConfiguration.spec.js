(function(_) {

var BindingConfiguration = this.Backbone.Fusion.BindingConfiguration;
var configuration;

describe('Backbone.Fusion.BindingConfiguration', function() {
	beforeEach(function() {
		configuration = new BindingConfiguration();
	});
	describe('merge()', function() {
		it('should merge new values', function() { 
			configuration = configuration.merge({ value: 'setting' });
			expect(configuration.raw().value).toEqual('setting');
		});
		it('should replace existing values', function() {
			expect(configuration
				.merge({ value: 'first' })
				.merge({ value: 'second' })
				.raw()
			).toEqual({ value: 'second' });
		});
		it('should create a new instance', function() {
			var merged = configuration.merge({ value: 'abc' });
			expect(merged !== configuration).toEqual(true);
		});
		it('should merge attribute configuration', function() {
			expect(configuration
				.merge({'@name':{format:'text'}})
				.merge({'@age':{format:'integer'}})
				.raw()
			).toEqual({'@name':{format:'text'}, '@age':{format:'integer'}});
		});
		it('should replace existing attribute configuration', function() {
			expect(configuration
				.merge({'@age':{format:'positive-integer'}})
				.merge({'@age':{format:'non-negative-integer'}})
				.raw()
			).toEqual({'@age':{format:'non-negative-integer'}});
		});
		it('should combine attribute configuration', function() {
			expect(configuration
				.merge({'@name':{format:'text'}})
				.merge({'@name':{events:['change','keyup']}})
				.raw()
			).toEqual({'@name':{format:'text', events:['change','keyup']}});
		});
		describe('operator', function() {
			it('should throw on invalid operator', function() {
				expect(function() { configuration.merge({ $invalid: 1 }); }).toThrow('invalid operator: $invalid');
			});
			describe('$reset', function() {
				it('should clear values', function() {
					expect(configuration
						.merge({ value: 123 })
						.merge({ $reset: true })
						.raw()
					).toEqual({ });
				});
				it('should clear values before writing new ones', function() {
					configuration = configuration.merge({ first: 'first' });
					expect(configuration.raw()).toEqual({ first: 'first' });
					configuration = configuration.merge({ second: 'second', $reset: true });
					expect(configuration.raw()).toEqual({ second: 'second' });
				});
				it('should clear specified value', function() {
					expect(configuration
						.merge({ one: 1, other: 2 })
						.merge({ $reset: 'one' })
						.raw()
					).toEqual({ other: 2 });
				});
				it('should clear multiple specified values', function() {
					expect(configuration
						.merge({ larry:1, curly:2, moe:3 })
						.merge({ $reset:['larry','moe'] })
						.raw()
					).toEqual({ curly:2 });
				});
				it('should clear values in attribue context', function() {
					expect(configuration
						.merge({events:['change','keyup'], '@age':{format:'non-negative-integer'}})
						.merge({ '@age':{$reset:true}})
						.raw()
					).toEqual({events:['change','keyup'], '@age':{}});
				});
			});
		});
		describe('should throw an exception when passed', function() {
			it('null', function() {
				expect(function() { configuration.merge(null); }).toThrow();
			});
			it('string', function() {
				expect(function() { configuration.merge('abc'); }).toThrow();
			});
		});
	});
	describe('get()', function() {
		it('should get configuration specified for the provided attribute name', function() {
			expect(configuration
				.merge({ '@name': { format: 'text' } })
				.get('name')
				.raw()
			).toEqual({ format: 'text' });
		});
		it('should include global configuration with attribute configuration', function() {
			expect(configuration
				.merge({ format: 'text', '@name': { events: ['change', 'keyup'] } })
				.get('name')
				.raw()
			).toEqual({ format: 'text', events: ['change', 'keyup'] });
		});
		it('should prefer attribute configuration to global configuration', function() {
			expect(configuration
				.merge({ format: 'text', '@age': { format: 'positive-integer' }})
				.get('age')
				.raw()
			).toEqual({ format: 'positive-integer' });
		});
	});
});

}).call(this, _);
