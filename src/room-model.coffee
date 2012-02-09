Backbone = require 'backbone'
Message = require('./schema/message-schema')
User = require('./schema/user-schema')
RoomSchema = require './schema/room-schema'
Dice = require './dice'
ObjectId = require('mongoose').Types.ObjectId;

class RoomModel extends Backbone.Model

  defaults:
    static: false
    closed: false

  message: Message

  user: User

  schema: RoomSchema

  initialize: () ->
    @joinedMembers = {}
    @bufferSize = 50

    if @id and @id instanceof ObjectId
      @set '_id', @id
    else if @id
      @set '_id', new ObjectId(@id)

    id = @get '_id'
    @id = id  if id
    @id = @id.toString?() || @id if @id

  addBuffer: (client, data, callback) ->
    client.get 'socket_token', (err, socket_token) =>
      throw new Error("can not find stored soket token.") if err or not socket_token
      @user.findOne {socket_token: socket_token}, (err, doc) =>
        throw new Error("unmatched socket token.") unless doc
        if dice_string = Dice.searchString data.body
          rolled = new Dice dice_string
          data.dice = rolled.rollResult
          data.body = Dice.removeString data.body
        message = new @message(data)
        message.alias = doc.name unless data.alias
        message.user_id = doc.id
        message.room_id = @id
        message.save (err) ->
          throw err if err
          callback(message.toObject())


  getBuffer: (callback) ->
    @message.find({room_id: @id}, {}, {sort:{_id: -1}, limit: @bufferSize}, (err, docs) =>
      throw err if err
      result = docs.map((doc) =>
        message = doc.toObject()
        message.id = message._id.toString()
        message.created = @dateFormat message.created_at
        message
      )
      callback result
    )

  getJoinedMember: (client) ->
    @joinedMembers[client.id]

  getJoinedMembers: ->
    for key, member of @joinedMembers
      member

  joinMember: (client, user, callback) ->
    throw new Error("user id or name undefined.") unless user.id and user.name and user.socket_token
    @user.findOne({id: user.id, socket_token: user.socket_token}, (err, doc) =>
      throw err if err
      throw new Error("Authentication failure.") unless doc
      data =
        id: doc.id
        name: doc.name
      data.alias = user.alias if user.alias
      @joinedMembers[client.id] = data
      callback(doc) if callback
    )

  leaveMember: (client) ->
    delete @joinedMembers[client.id]
    client.broadcast.to(@id).emit('updateJoinedMembers', @id, @joinedMembers);
    client.leave @id

  dateFormat: (date) ->
    date.getFullYear() + "-" + ("0" + (date.getMonth() + 1)).substr(-2) + "-" + ("0" + date.getDate()).substr(-2) + " " + ("0" + date.getHours()).substr(-2) + ":" + ("0" + date.getMinutes()).substr(-2) + ":" + ("0" + date.getSeconds()).substr(-2)

  sync: (method, model, options) ->
    switch method
      when "create"
        doc = new @schema(model.attributes)
        doc.save (err) ->
          throw err if err
          json = doc.toJSON()
          json.id = json._id.toString()
          options.success(json)
      when "update"
        @schema.findById model.id, (err, doc) ->
          doc.set model.attributes
          doc.save (err) ->
            throw err if err
            json = doc.toJSON()
            json.id = json._id.toString()
            options.success(json)

module.exports = RoomModel