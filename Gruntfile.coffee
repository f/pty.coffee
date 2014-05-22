path = require 'path'

module.exports = (grunt)->

  require("load-grunt-tasks") grunt

  grunt.initConfig
    # GYP Settings
    gyp:
      configure: command: 'configure'
      build    : command: 'build'
      clean    : command: 'clean'

  grunt.registerTask 'gyp-build', ['gyp:clean', 'gyp:configure', 'gyp:build']
  grunt.registerTask 'build'

  grunt.registerTask 'default', ['gyp-build']
