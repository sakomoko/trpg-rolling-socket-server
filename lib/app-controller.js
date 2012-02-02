var AppController, RoomCollection;

RoomCollection = require('./room-collection');

AppController = (function() {

  function AppController() {
    this.rooms = new RoomCollection();
  }

  AppController.prototype.bindAllEvents = function(socket) {
    var fn, key, _ref, _results;
    _ref = this.events;
    _results = [];
    for (key in _ref) {
      fn = _ref[key];
      _results.push(fn.apply(this, [socket]));
    }
    return _results;
  };

  AppController.prototype.events = {
    getRoomLog: function(socket) {
      var _this = this;
      return socket.on('getRoomLog', function(roomId) {
        return _this.rooms.get(roomId).getBuffer(socket, function(socket, docs) {
          return socket.emit('pushMessage', roomId, docs);
        });
      });
    },
    joinMember: function(socket) {
      var _this = this;
      return socket.on('joinMember', function(roomId, user, fn) {
        return _this.rooms.get(roomId).joinMember(socket, user, function() {
          var members;
          socket.emit('successJoined', roomId, user);
          members = this.rooms.get(roomId).getJoinedMembers();
          socket.to(roomId).emit('updateJoinedMembers', roomId, members);
          if (fn) return fn();
        });
      });
    },
    getJoinedMembers: function(socket) {
      var _this = this;
      return socket.on('getJoinedMembers', function(roomId) {
        return socket.emit('updateJoinedMembers', roomId, _this.rooms.get(roomId).getJoinedMembers());
      });
    },
    sendMessage: function(socket) {
      var _this = this;
      return socket.on('sendMessage', function(roomId, data) {
        try {
          return _this.rooms.get(roomId).addBuffer(socket, data, function(msg) {
            return socket.to(roomId).emit('pushMessage', roomId, msg);
          });
        } catch (e) {
          return socket.emit('socketFaild', e.message);
        }
      });
    }
  };

  return AppController;

})();

module.exports = AppController;
