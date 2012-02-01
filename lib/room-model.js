var Backbone, Dice, Message, RoomModel, User,
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

Backbone = require('backbone');

Message = require('./schema/message-schema');

User = require('./schema/user-schema');

Dice = require('./dice');

RoomModel = (function(_super) {

  __extends(RoomModel, _super);

  function RoomModel() {
    RoomModel.__super__.constructor.apply(this, arguments);
  }

  RoomModel.prototype.defaults = {
    is_static: false,
    is_closed: false
  };

  RoomModel.prototype.message = Message;

  RoomModel.prototype.user = User;

  RoomModel.prototype.initialize = function() {
    this.joinedMembers = {};
    return this.bufferSize = 50;
  };

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

  RoomModel.prototype.joinMember = function(client, user, callback) {
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
      client.socket_token = user.socket_token;
      if (callback) return callback(client);
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

})(Backbone.Model);

module.exports = RoomModel;
