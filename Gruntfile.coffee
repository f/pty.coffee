path = require 'path'

module.exports = (grunt)->

  require("load-grunt-tasks") grunt

  grunt.initConfig
    # GYP Settings
    gyp:
      configure:
        command: 'configure'
      build    :
        command: 'build'

  grunt.registerTask 'gyp-build', ['gyp:configure', 'gyp:build']

  grunt.registerTask 'default', ['gyp-build']
