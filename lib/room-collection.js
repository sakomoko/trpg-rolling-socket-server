var Backbone, Room, RoomCollection, RoomSchema,
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

Backbone = require('backbone');

Room = require('./room-model');

RoomSchema = require('./schema/room-schema');

RoomCollection = (function(_super) {

  __extends(RoomCollection, _super);

  function RoomCollection() {
    RoomCollection.__super__.constructor.apply(this, arguments);
  }

  RoomCollection.prototype.model = Room;

  RoomCollection.prototype.schema = RoomSchema;

  RoomCollection.prototype.sync = function(method, model, options) {
    switch (method) {
      case "read":
        return this.schema.find({
          closed_at: {
            $exits: false
          }
        }, {
          sort: {
            _id: 1
          }
        }, function(err, docs) {
          if (err) throw err;
          return options.success(docs);
        });
    }
  };

  RoomCollection.prototype.getOpenRooms = function(cb) {
    return this.sync("read", this, {
      success: cb
    });
  };

  return RoomCollection;

})(Backbone.Collection);

module.exports = RoomCollection;
