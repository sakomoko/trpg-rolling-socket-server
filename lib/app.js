var AppController, app, express, io, mongoose, port, sio;

express = require('express');

sio = require('socket.io');

mongoose = require('mongoose');

AppController = require('./app-controller');

app = express.createServer();

port = 55555;

mongoose.connect('mongodb://localhost/trpg-rolling');

app.get("/", function(req, res) {
  return res.send("Not Found.", 404);
});

app.listen(port);

io = sio.listen(app);

io.configure("production", function() {
  io.set("log level", 1);
  return io.enable("browser client etag");
});

io.sockets.on("connection", function(socket) {
  controller.attachEventHandler(socket);
  return socket.on("disconnect", function() {
    return controller.disconnect(socket);
  });
});

process.on("uncaughtException", function(err) {
  return console.log("Caught exception: " + err);
});

console.log("Server running at http://127.0.0.1:" + port + "/");
