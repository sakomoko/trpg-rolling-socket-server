var AppController, RoomCollection;

RoomCollection = require('./room-collection');

AppController = (function() {

  function AppController() {
    this.rooms = new RoomCollection();
  }

  AppController.prototype.bindAllEvents = function(client) {
    var fn, key, _ref, _results;
    _ref = this.events;
    _results = [];
    for (key in _ref) {
      fn = _ref[key];
      _results.push(fn.apply(this, [client]));
    }
    return _results;
  };

  AppController.prototype.events = {
    getRoomLog: function(client) {
      var _this = this;
      return client.on('getRoomLog', function(roomId) {
        return _this.rooms.get(roomId).getBuffer(client, function(client, docs) {
          return client.emit('pushMessage', roomId, docs);
        });
      });
    },
    joinMember: function(client) {
      var _this = this;
      return client.on('joinMember', function(roomId, user, fn) {
        return _this.rooms.get(roomId).joinMember(client, user, function() {
          var members;
          client.emit('successJoined', roomId, user);
          members = this.rooms.get(roomId).getJoinedMembers();
          client.to(roomId).emit('updateJoinedMembers', roomId, members);
          if (fn) return fn();
        });
      });
    }
  };

  return AppController;

})();

module.exports = AppController;
