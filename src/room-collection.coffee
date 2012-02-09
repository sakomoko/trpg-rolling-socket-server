Backbone = require 'backbone'
Room = require('./room-model')
RoomSchema = require './schema/room-schema'
class RoomCollection extends Backbone.Collection

  model: Room

  schema: RoomSchema

  sync: (method, model, options) ->
    switch method
      when "read"
        @schema.find({closed_at: {$exits: false}}, {sort:{_id: 1}}, (err, docs) ->
          throw err if err
          options.success(docs)
        )

  getOpenRooms: (cb) ->
    @.sync "read", @, success: cb

module.exports = RoomCollection