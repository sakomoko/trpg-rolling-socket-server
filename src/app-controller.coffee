RoomCollection = require './room-collection'
class AppController

  constructor: () ->
    @rooms = new RoomCollection()

  bindAllEvents: (client) ->
    fn.apply @, [client] for key, fn of @events

  events:
    getRoomLog: (client) ->
      client.on 'getRoomLog', (roomId) =>
        @rooms.get(roomId).getBuffer client, (client, docs)->
          client.emit 'pushMessage', roomId, docs

    joinMember: (client) ->
      client.on 'joinMember', (roomId, user, fn) =>
        @rooms.get(roomId).joinMember(client, user, ->
          client.emit('successJoined', roomId, user)
          members = @rooms.get(roomId).getJoinedMembers()
          client.to(roomId).emit('updateJoinedMembers', roomId, members)
          fn() if fn
        )

module.exports = AppController