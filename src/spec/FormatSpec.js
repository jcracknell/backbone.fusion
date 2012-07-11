// TODO: remove if supported by jasmine
jasmine.Matchers.prototype.toBeNaN = function() {
	return (typeof this.actual === 'number' && this.actual !== this.actual);
};

(function(_, $) {
	var Formats = this.Backbone.Fusion.Formats;
	var format = null;
	var context = null;

	describe('Backbone.Fusion.Formats', function() {
		describe("'integer' format", function() {
			beforeEach(function() {
				format = Formats['integer'];
			});
			describe('when reading', function() {
				beforeEach(function() {
					context = { direction: 'r' };
				});
				it("should convert '8' to integer value", function() {
					expect(format('8', context)).toEqual(8);
				});
				it("should convert 'bla' to NaN", function() {
					expect(format('bla', context)).toBeNaN();
				});
				it("should convert '-8' to integer value", function() {
					expect(format('-8', context)).toEqual(-8);
				});
			});
			describe('when writing', function() {
				beforeEach(function() {
					context = { direction: 'w' };
				});
			});
		});
		describe("'float' format", function() {
			beforeEach(function() {
				format = Formats['float'];
			});
			describe('when reading', function() {
				beforeEach(function() {
					context = { direction: 'r' };
				});
				it("should convert '8.1' to float value", function() {
					expect(format('8.1', context)).toEqual(8.1);
				});
				it("should convert 'bla' to NaN", function() {
					expect(format('bla', context)).toBeNaN();
				});
				it("should convert '-8.1' to float value", function() {
					expect(format('-8.1', context)).toEqual(-8.1);
				});
			});	
			describe('when reading', function() {
				beforeEach(function() {
					context = { direction: 'w' };
				});
			});	
		});
	});
}).call(this, _, jQuery);
