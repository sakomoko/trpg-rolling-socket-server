var AppController, RoomCollection;

RoomCollection = require('./room-collection');

AppController = (function() {
  var _this = this;

  function AppController() {}

  AppController.prototype.rooms = new RoomCollection();

  AppController.prototype.bindAllEvents = function(client) {
    var fn, key, _ref, _results;
    _ref = this.events;
    _results = [];
    for (key in _ref) {
      fn = _ref[key];
      _results.push(fn(client));
    }
    return _results;
  };

  AppController.prototype.events = {
    getRoomLog: function(client) {
      return client.on('getRoomLog', function(roomId) {
        return AppController.rooms.get(roomId).getBuffer(client, function(client, docs) {
          return client.emit('pushMessage', roomId, docs);
        });
      });
    }
  };

  return AppController;

}).call(this);

module.exports = AppController;
