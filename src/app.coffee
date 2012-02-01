express = require('express')
sio  = require('socket.io')
mongoose = require('mongoose')

AppController = require('./app-controller')

app = express.createServer()
port = 55555

mongoose.connect('mongodb://localhost/trpg-rolling')

app.get "/", (req, res) ->
  res.send "Not Found.", 404

app.listen port
io = sio.listen(app)
io.configure "production", ->
  io.set "log level", 1
  io.enable "browser client etag"

io.sockets.on "connection", (socket) ->
  controller.attachEventHandler socket
  socket.on "disconnect", ->
    controller.disconnect socket

process.on "uncaughtException", (err) ->
  console.log "Caught exception: " + err

console.log "Server running at http://127.0.0.1:" + port + "/"
