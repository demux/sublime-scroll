module.exports = (grunt) ->
  grunt.initConfig
    livescript:
      src:
        files:
          'build/sublimeScroll.js': 'src/sublimeScroll.ls'
          'build/sublimeScrollLite.js': 'src/sublimeScrollLite.ls'

    stylus:
      compile:
        files:
          'build/sublimeScroll.css': 'src/sublimeScroll.styl'
          'build/sublimeScrollLite.css': 'src/sublimeScrollLite.styl'

    watch:
     livescript:
        files: ['src/*.ls']
        tasks: ['livescript']
      stylus:
        files: ['src/*.styl']
        tasks: ['stylus']

  # load tasks
  grunt.loadNpmTasks 'grunt-livescript'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-stylus'

  # register tasks
  grunt.registerTask 'default', ['livescript', 'stylus']
