const path = require('path');

module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    shell: {
      test: {
        command: `${path.normalize('node_modules/.bin/jasmine-focused')} --captureExceptions --forceexit spec`,
        options: {
          stdout: true,
          stderr: true,
          failOnError: true
        }
      },

      'update-atomdoc': {
        command: 'npm update grunt-atomdoc donna tello atomdoc',
        options: {
          stdout: true,
          stderr: true,
          failOnError: true
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-shell');
  grunt.loadNpmTasks('grunt-atomdoc');

  return grunt.registerTask('test', ['shell:test']);
};
