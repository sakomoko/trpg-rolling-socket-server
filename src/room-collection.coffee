Backbone = require 'backbone'
Room = require('./room-model')
RoomSchema = require './schema/room-schema'
class RoomCollection extends Backbone.Collection

  model: Room

  schema: RoomSchema

  sync: (method, model, options) ->
    switch method
      when "read"
        @schema.find({is_closed: 0}, {sort:{_id: 1}}, (err, docs) ->
          throw err if err
          options.success(docs)
        )

module.exports = RoomCollection