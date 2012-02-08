RoomCollection = require './room-collection'
class AppController

  constructor: () ->
    @rooms = new RoomCollection()

  bindAllEvents: (socket) ->
    fn.apply @, [socket] for key, fn of @events

  events:
    getRoomLog: (socket) ->
      socket.on 'getRoomLog', (roomId) =>
        @rooms.get(roomId).getBuffer (docs)->
          socket.emit 'pushMessage', roomId, docs

    joinMember: (socket) ->
      socket.on 'joinMember', (roomId, user, fn) =>
        @rooms.get(roomId).joinMember socket, user, ->
          socket.emit('successJoined', roomId, user)
          members = @rooms.get(roomId).getJoinedMembers()
          socket.to(roomId).emit('updateJoinedMembers', roomId, members)
          fn() if fn

    getJoinedMembers: (socket) ->
      socket.on 'getJoinedMembers', (roomId) =>
        socket.emit 'updateJoinedMembers', roomId, @rooms.get(roomId).getJoinedMembers()

    sendMessage: (socket) ->
      socket.on 'sendMessage', (roomId, data) =>
        try
          @rooms.get(roomId).addBuffer socket, data, (msg) ->
            socket.to(roomId).emit('pushMessage', roomId, msg)
        catch e
          socket.emit('socketFaild', e.message)


module.exports = AppController