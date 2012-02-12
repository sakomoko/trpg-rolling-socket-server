io = null
app = null
#
# Module dependencies.
#
#
mongoose = require('mongoose')
database =
  production: 'mongodb://localhost/trpg_rolling'
  development: 'mongodb://localhost/trpg_rolling_development'
  test: 'mongodb://localhost/trpg_rolling_test'

env = process.env.NODE_ENV ? 'test'

exports.run = (port=5000, cb) ->
  mongoose.connect(database[env])
  exports.app = app = new exports.AppController()
  app.rooms.fetch reset: true
  app.io = io = require('socket.io').listen port, cb

  io.configure "production", ->
    io.enable 'browser client minification'
    io.enable 'browser client etag'
    io.enable 'browser client gzip'
    io.set "log level", 1
    io.set('transports', [
      'websocket'
      'flashsocket'
       'htmlfile'
      'xhr-polling'
      'jsonp-polling'
    ])
    process.on "uncaughtException", (err) ->
      io.log.error "Caught exception: " + err

  io.sockets.on 'connection', (socket) ->
    app.bindAllEvents socket


  io.log.info "Server running at http://127.0.0.1:" + port + "/"
  app

exports.stop = (cb) ->
  io.server.close()
  mongoose.disconnect ->
    cb?()



#
# AppController constructor.
#
#
exports.AppController = require('./app-controller')

#
# RoomCollection constructor.
#
#
exports.RoomCollection = require('./room-collection')

#
# RoomModel constructor
#
#
exports.RoomModel = require('./room-model')




