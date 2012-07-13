module.exports = function(grunt) {
	grunt.initConfig({
		lint: {
			all: ['src/**/*.js']
		},
		min: {
			dist: {
				src: ['src/backbone.fusion.js'],
				dest: 'dist/backbone.fusion.min.js'
			}	
		}
	});

	grunt.registerTask('default', 'min');
};
