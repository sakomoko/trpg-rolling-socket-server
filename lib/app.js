var app, database, env, io, mongoose, _ref;

io = null;

app = null;

mongoose = require('mongoose');

database = {
  production: 'mongodb://localhost/trpg_rolling',
  development: 'mongodb://localhost/trpg_rolling_development',
  test: 'mongodb://localhost/trpg_rolling_test'
};

env = (_ref = process.env.NODE_ENV) != null ? _ref : 'test';

exports.run = function(port, cb) {
  if (port == null) port = 5000;
  mongoose.connect(database[env]);
  exports.app = app = new exports.AppController();
  app.rooms.fetch({
    reset: true
  });
  app.io = io = require('socket.io').listen(port, cb);
  io.configure("production", function() {
    io.enable('browser client minification');
    io.enable('browser client etag');
    io.enable('browser client gzip');
    io.set("log level", 1);
    io.set('transports', ['websocket', 'flashsocket', 'htmlfile', 'xhr-polling', 'jsonp-polling']);
    return process.on("uncaughtException", function(err) {
      return io.log.error("Caught exception: " + err);
    });
  });
  io.sockets.on('connection', function(socket) {
    return app.bindAllEvents(socket);
  });
  io.log.info("Server running at http://127.0.0.1:" + port + "/");
  return app;
};

exports.stop = function(cb) {
  io.server.close();
  return mongoose.disconnect(function() {
    return typeof cb === "function" ? cb() : void 0;
  });
};

exports.AppController = require('./app-controller');

exports.RoomCollection = require('./room-collection');

exports.RoomModel = require('./room-model');
