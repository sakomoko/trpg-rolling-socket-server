Message = require('./schema/message-schema')
User = require('./schema/user-schema')
Dice = require './dice'
class RoomModel
  constructor: (@id, @message = Message, @user = User, @bufferSize=50) ->
    @joinedMembers = {}

  addBuffer: (client, data, callback) ->
    @user.findOne({socket_token: client.socket_token}, (err, doc) =>
      throw new Error("unmatched socket token.") unless doc
      if dice_string = Dice.searchString data.body
        rolled = new Dice dice_string
        data.dice = rolled.rollResult
        data.body = Dice.removeString data.body
      message = new @message(data)
      message.alias = doc.name unless data.alias
      message.user_id = doc.id
      message.room_id = @id
      message.save((err) ->
        throw err if err
        callback(message.toObject())
      )
    )

  getBuffer: (client, callback) ->
    @message.find({room_id: @id}, {}, {sort:{_id: -1}, limit: @bufferSize}, (err, docs) =>
      return false unless docs
      result = docs.map((doc) =>
        message = doc.toObject()
        message.created = @dateFormat message.created_at
        message
      )
      callback client, result
    )

  getJoinedMember: (client) ->
    @joinedMembers[client.id]

  joinMember: (client, user) ->
    throw new Error("user id or name undefined.") unless user.id and user.name
    @user.findOne({id: user.id, socket_token: user.socket_token}, (err, doc) =>
      throw err if err
      throw new Error("Authentication failure.") unless doc
      data =
        id: user.id
        name: user.name
        socket_token: user.socket_token
      @joinedMembers[client.id] = data
      client.socket_token = user.socket_token
    )

  leaveMember: (client) ->
    delete @joinedMembers[client.id]
    client.broadcast().to(@id).emit('updateJoinedMembers', @id, @joinedMembers);
    client.leave @id

  dateFormat: (date) ->
    date.getFullYear() + "-" + ("0" + (date.getMonth() + 1)).substr(-2) + "-" + ("0" + date.getDate()).substr(-2) + " " + ("0" + date.getHours()).substr(-2) + ":" + ("0" + date.getMinutes()).substr(-2) + ":" + ("0" + date.getSeconds()).substr(-2)

exports.RoomModel = RoomModel