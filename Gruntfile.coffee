path = require('path')

module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    coffeelint:
      options:
        no_empty_param_list:
          level: 'error'
        max_line_length:
          level: 'ignore'
        indentation:
          level: 'ignore'

      test: ['spec/*.coffee']
      gruntfile: ['Gruntfile.coffee']

    shell:
      test:
        command: "#{path.normalize('node_modules/.bin/jasmine-focused')} --coffee --captureExceptions --forceexit spec"
        options:
          stdout: true
          stderr: true
          failOnError: true

      'update-atomdoc':
        command: 'npm update grunt-atomdoc donna tello atomdoc'
        options:
          stdout: true
          stderr: true
          failOnError: true

  grunt.loadNpmTasks('grunt-shell')
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-atomdoc')

  grunt.registerTask('lint', ['coffeelint'])
  grunt.registerTask('default', ['lint'])
  grunt.registerTask('test', ['lint', 'shell:test'])
