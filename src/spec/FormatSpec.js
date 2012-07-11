// TODO: remove if supported by jasmine
jasmine.Matchers.prototype.toBeNaN = function() {
	return (typeof this.actual === 'number' && this.actual !== this.actual);
};

(function(_, $) {
	var Formats = this.Backbone.Fusion.Formats;
	var format = null;
	var context = null;

	describe('Backbone.Fusion.Formats', function() {
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
				it("should convert '0' to float value", function() {
					expect(format('0', context)).toEqual(0);
				});
				it("should convert '-8.1' to float value", function() {
					expect(format('-8.1', context)).toEqual(-8.1);
				});
				it("should convert '.8' to float value", function() {
					expect(format('.8', context)).toEqual(0.8);
				});
				it("should convert '8.' to float value", function() {
					expect(format('8.', context)).toEqual(8.0);
				});
				it("should convert '1,234.567' to float value", function() {
					expect(format('1,234.567', context)).toEqual(1234.567);
				});
				it("should convert 'bla' to NaN", function() {
					expect(format('bla', context)).toBeNaN();
				});
			});	
			describe('when writing', function() {
				beforeEach(function() {
					context = { direction: 'w' };
				});
			});	
		});
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
				it("should convert '-8' to integer value", function() {
					expect(format('-8', context)).toEqual(-8);
				});
				it("should convert 'bla' to NaN", function() {
					expect(format('bla', context)).toBeNaN();
				});
			});
			describe('when writing', function() {
				beforeEach(function() {
					context = { direction: 'w' };
				});
			});
		});
		describe("'negative-integer' format", function() {
			beforeEach(function() {
				format = Formats['negative-integer'];
			});
			describe('when reading', function() {
				beforeEach(function() {
					context = { direction: 'r' };
				});
				it("should convert '8' to NaN", function() {
					expect(format('8', context)).toBeNaN();
				});
				it("should convert '0' to NaN", function() {
					expect(format('0', context)).toBeNaN();
				});
				it("should convert '-8' to number value", function() {
					expect(format('-8', context)).toEqual(-8);
				});
			});
		});
		describe("'non-negative-integer' format", function() {
			beforeEach(function() {
				format = Formats['non-negative-integer'];
			});
			describe('when reading', function() {
				beforeEach(function() {
					context = { direction: 'r' };
				});
				it("should convert '8' to integer value", function() {
					expect(format('8', context)).toEqual(8);
				});
				it("should convert '0' to integer value", function() {
					expect(format('0', context)).toEqual(0);
				});
				it("should convert '-1' to NaN", function() {
					expect(format('-1', context)).toBeNaN();
				});
			});	
		});
		describe("'non-positive-integer' format", function() {
			beforeEach(function() {
				format = Formats['non-positive-integer'];
			});
			describe('when reading', function() {
				it("should convert '8' to NaN", function() {
					expect(format('8', context)).toBeNaN();
				});
				it("should convert '0' to number value", function() {
					expect(format('0', context)).toEqual(0);
				});
				it("should convert '-8' to number value", function() {
					expect(format('-8', context)).toEqual(-8);
				});
			});
		});
		describe("'positive-integer' format", function() {
			beforeEach(function() {
				format = Formats['positive-integer'];
			});
			describe('when reading', function() {
				beforeEach(function() {
					context = { direction: 'r' };
				});
				it("should convert '8' to integer value", function() {
					expect(format('8', context)).toEqual(8);
				});
				it("should convert '0' to NaN", function() {
					expect(format('0', context)).toBeNaN();
				});
				it("should convert '-1' to NaN", function() {
					expect(format('-1', context)).toBeNaN();
				});
			});	
			describe('when writing', function() {
				beforeEach(function() {
					context = { direction: 'w' };
				});
			});	
		});
	});
}).call(this, _, jQuery);
