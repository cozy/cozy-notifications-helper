{exec} = require 'child_process'

task 'build', 'build src into lib', ->
    exec "coffee --output lib --compile src"

task 'tests', 'run tests', ->
    command  = "mocha tests/server.coffee --reporter spec "
    command += "--compilers coffee:coffee-script --colors"
    exec command, (err, stdout, stderr) ->
        console.log "Running mocha caught exception: \n" + err if err
        console.log stdout