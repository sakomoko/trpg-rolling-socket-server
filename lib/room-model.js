var Dice, Message, RoomModel, User;

Message = require('./schema/message-schema');

User = require('./schema/user-schema');

Dice = require('./dice');

RoomModel = (function() {

  function RoomModel(id, message, user, bufferSize) {
    this.id = id;
    this.message = message != null ? message : Message;
    this.user = user != null ? user : User;
    this.bufferSize = bufferSize != null ? bufferSize : 50;
    this.joinedMembers = {};
  }

  RoomModel.prototype.addBuffer = function(client, data, callback) {
    var _this = this;
    return this.user.findOne({
      socket_token: client.socket_token
    }, function(err, doc) {
      var dice_string, message, rolled;
      if (!doc) throw new Error("unmatched socket token.");
      if (dice_string = Dice.searchString(data.body)) {
        rolled = new Dice(dice_string);
        data.dice = rolled.rollResult;
        data.body = Dice.removeString(data.body);
      }
      message = new _this.message(data);
      if (!data.alias) message.alias = doc.name;
      message.user_id = doc.id;
      message.room_id = _this.id;
      return message.save(function(err) {
        if (err) throw err;
        return callback(message.toObject());
      });
    });
  };

  RoomModel.prototype.getBuffer = function(client, callback) {
    var _this = this;
    return this.message.find({
      room_id: this.id
    }, {}, {
      sort: {
        _id: -1
      },
      limit: this.bufferSize
    }, function(err, docs) {
      var result;
      if (!docs) return false;
      result = docs.map(function(doc) {
        var message;
        message = doc.toObject();
        message.created = _this.dateFormat(message.created_at);
        return message;
      });
      return callback(client, result);
    });
  };

  RoomModel.prototype.getJoinedMember = function(client) {
    return this.joinedMembers[client.id];
  };

  RoomModel.prototype.joinMember = function(client, user) {
    var _this = this;
    if (!(user.id && user.name)) throw new Error("user id or name undefined.");
    return this.user.findOne({
      id: user.id,
      socket_token: user.socket_token
    }, function(err, doc) {
      var data;
      if (err) throw err;
      if (!doc) throw new Error("Authentication failure.");
      data = {
        id: user.id,
        name: user.name,
        socket_token: user.socket_token
      };
      _this.joinedMembers[client.id] = data;
      return client.socket_token = user.socket_token;
    });
  };

  RoomModel.prototype.leaveMember = function(client) {
    delete this.joinedMembers[client.id];
    client.broadcast().to(this.id).emit('updateJoinedMembers', this.id, this.joinedMembers);
    return client.leave(this.id);
  };

  RoomModel.prototype.dateFormat = function(date) {
    return date.getFullYear() + "-" + ("0" + (date.getMonth() + 1)).substr(-2) + "-" + ("0" + date.getDate()).substr(-2) + " " + ("0" + date.getHours()).substr(-2) + ":" + ("0" + date.getMinutes()).substr(-2) + ":" + ("0" + date.getSeconds()).substr(-2);
  };

  return RoomModel;

})();

exports.RoomModel = RoomModel;
