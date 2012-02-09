var Backbone, Dice, Message, ObjectId, RoomModel, RoomSchema, User,
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

Backbone = require('backbone');

Message = require('./schema/message-schema');

User = require('./schema/user-schema');

RoomSchema = require('./schema/room-schema');

Dice = require('./dice');

ObjectId = require('mongoose').Types.ObjectId;

RoomModel = (function(_super) {

  __extends(RoomModel, _super);

  function RoomModel() {
    RoomModel.__super__.constructor.apply(this, arguments);
  }

  RoomModel.prototype.defaults = {
    static: false,
    closed: false
  };

  RoomModel.prototype.message = Message;

  RoomModel.prototype.user = User;

  RoomModel.prototype.schema = RoomSchema;

  RoomModel.prototype.initialize = function() {
    var id, _base;
    this.joinedMembers = {};
    this.bufferSize = 50;
    if (this.id && this.id instanceof ObjectId) {
      this.set('_id', this.id);
    } else if (this.id) {
      this.set('_id', new ObjectId(this.id));
    }
    id = this.get('_id');
    if (id) this.id = id;
    if (this.id) {
      return this.id = (typeof (_base = this.id).toString === "function" ? _base.toString() : void 0) || this.id;
    }
  };

  RoomModel.prototype.addBuffer = function(client, data, callback) {
    var _this = this;
    return client.get('socket_token', function(err, socket_token) {
      if (err || !socket_token) {
        throw new Error("can not find stored soket token.");
      }
      return _this.user.findOne({
        socket_token: socket_token
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
    });
  };

  RoomModel.prototype.getBuffer = function(callback) {
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
      if (err) throw err;
      result = docs.map(function(doc) {
        var message;
        message = doc.toObject();
        message.id = message._id.toString();
        message.created = _this.dateFormat(message.created_at);
        return message;
      });
      return callback(result);
    });
  };

  RoomModel.prototype.getJoinedMember = function(client) {
    return this.joinedMembers[client.id];
  };

  RoomModel.prototype.getJoinedMembers = function() {
    var key, member, _ref, _results;
    _ref = this.joinedMembers;
    _results = [];
    for (key in _ref) {
      member = _ref[key];
      _results.push(member);
    }
    return _results;
  };

  RoomModel.prototype.joinMember = function(client, user, callback) {
    var _this = this;
    if (!(user.id && user.name && user.socket_token)) {
      throw new Error("user id or name undefined.");
    }
    return this.user.findOne({
      id: user.id,
      socket_token: user.socket_token
    }, function(err, doc) {
      var data;
      if (err) throw err;
      if (!doc) throw new Error("Authentication failure.");
      data = {
        id: doc.id,
        name: doc.name
      };
      if (user.alias) data.alias = user.alias;
      _this.joinedMembers[client.id] = data;
      if (callback) return callback(doc);
    });
  };

  RoomModel.prototype.leaveMember = function(client) {
    return delete this.joinedMembers[client.id];
  };

  RoomModel.prototype.dateFormat = function(date) {
    return date.getFullYear() + "-" + ("0" + (date.getMonth() + 1)).substr(-2) + "-" + ("0" + date.getDate()).substr(-2) + " " + ("0" + date.getHours()).substr(-2) + ":" + ("0" + date.getMinutes()).substr(-2) + ":" + ("0" + date.getSeconds()).substr(-2);
  };

  RoomModel.prototype.sync = function(method, model, options) {
    var doc;
    switch (method) {
      case "create":
        doc = new this.schema(model.attributes);
        return doc.save(function(err) {
          var json;
          if (err) throw err;
          json = doc.toJSON();
          json.id = json._id.toString();
          return options.success(json);
        });
      case "update":
        return this.schema.findById(model.id, function(err, doc) {
          if (!doc) return options.error('Document not found.');
          doc.set(model.attributes);
          return doc.save(function(err) {
            var json;
            if (err) throw err;
            json = doc.toJSON();
            json.id = json._id.toString();
            return options.success(json);
          });
        });
      case "read":
        return this.schema.findById(model.id, function(err, doc) {
          if (err) throw err;
          if (!doc) return options.error('Document not found.');
          return options.success(doc.toJSON());
        });
    }
  };

  return RoomModel;

})(Backbone.Model);

module.exports = RoomModel;
