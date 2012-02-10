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
        return _this.rooms.get(roomId).getBuffer(function(docs) {
          return socket.emit('pushMessage', roomId, docs);
        });
      });
    },
    joinMember: function(socket) {
      var _this = this;
      return socket.on('joinMember', function(roomId, user, fn) {
        try {
          return _this.rooms.get(roomId).joinMember(socket, user, function(userDoc) {
            return socket.set('socket_token', userDoc.socket_token, function() {
              var members;
              socket.join(roomId);
              socket.emit('successJoined', roomId, user);
              members = _this.rooms.get(roomId).getJoinedMembers();
              socket.to(roomId).emit('updateJoinedMembers', roomId, members);
              if (fn) return fn();
            });
          });
        } catch (e) {
          return socket.emit('socketFaild', e.message);
        }
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
    },
    sendTypingStatus: function(socket) {
      var _this = this;
      return socket.on('sendTypingStatus', function(roomId, isTyping) {
        var user;
        try {
          user = _this.rooms.get(roomId).getJoinedMember(socket);
          if (!user) throw new Error('user has not joined room.');
          return socket.broadcast.to(roomId).emit('pushTypingStatus', roomId, user, isTyping);
        } catch (e) {
          return socket.emit('socketFaild', e.message);
        }
      });
    },
    getRoomList: function(socket) {
      var _this = this;
      return socket.on('getRoomList', function() {
        return _this.rooms.getOpenRooms(function(roomList) {
          roomList = roomList.filter(function(doc) {
            var model;
            model = _this.rooms.get(doc.id.toString());
            return !model || !model.getJoinedMember(socket);
          });
          return socket.emit('pushRoomList', roomList);
        });
      });
    },
    leaveRoom: function(socket) {
      var _this = this;
      return socket.on('leaveRoom', function(roomId, cb) {
        var room;
        room = _this.rooms.get(roomId);
        if (!room) throw new Error('Room not found.');
        room.leaveMember(socket);
        socket.leave(room.id);
        socket.broadcast.to(roomId).emit('updateJoinedMembers', room.id, room.getJoinedMembers());
        if (!socket.manager.rooms['/' + room.id]) _this.rooms.remove(room.id);
        return typeof cb === "function" ? cb() : void 0;
      });
    },
    connectRoom: function(socket) {
      var _this = this;
      return socket.on('connectRoom', function(roomId, cb) {
        var room;
        room = _this.rooms.get(roomId);
        if (room) {
          socket.join(room.id);
          return typeof cb === "function" ? cb() : void 0;
        } else {
          room = new _this.rooms.model({
            id: roomId
          });
          return room.fetch({
            success: function(model) {
              _this.rooms.add(model);
              socket.join(model.id);
              return typeof cb === "function" ? cb() : void 0;
            },
            error: function() {
              throw new Error('Room not find.');
            }
          });
        }
      });
    },
    disconnect: function(socket) {
      var _this = this;
      return socket.on('disconnect', function() {
        var key, value, _ref, _results;
        _ref = socket.manager.roomClients[socket.id];
        _results = [];
        for (key in _ref) {
          value = _ref[key];
          _results.push(socket.emit('leaveRoom', key.slice(1)));
        }
        return _results;
      });
    }
  };

  return AppController;

})();

module.exports = AppController;
