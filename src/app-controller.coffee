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
        try
          @rooms.get(roomId).joinMember socket, user, (userDoc) =>
            socket.set 'socket_token', userDoc.socket_token, =>
              socket.join roomId
              socket.emit('successJoined', roomId, user)
              members = @rooms.get(roomId).getJoinedMembers()
              socket.to(roomId).emit('updateJoinedMembers', roomId, members)
              fn() if fn
        catch e
          socket.emit('socketFaild', e.message)

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

    sendTypingStatus: (socket) ->
      socket.on 'sendTypingStatus', (roomId, isTyping) =>
        try
          user = @rooms.get(roomId).getJoinedMember socket
          throw new Error('user has not joined room.') unless user
          socket.broadcast.to(roomId).emit 'pushTypingStatus', roomId, user, isTyping
        catch e
          socket.emit 'socketFaild', e.message

    getRoomList: (socket) ->
      socket.on 'getRoomList', =>
        @rooms.getOpenRooms (roomList) =>
          roomList = roomList.filter (doc)=>
            model = @rooms.get(doc.id.toString())
            (not model or not model.getJoinedMember socket)
          socket.emit 'pushRoomList', roomList

    leaveRoom: (socket) ->
      socket.on 'leaveRoom', (roomId, cb) =>
        room = @rooms.get roomId
        throw new Error('Room not found.') unless room
        room.leaveMember socket
        socket.leave room.id
        socket.broadcast.to(roomId).emit 'updateJoinedMembers', room.id, room.getJoinedMembers()
        @rooms.remove room.id unless socket.manager.rooms['/' + room.id]
        cb?()

    connectRoom: (socket) ->
      socket.on 'connectRoom', (roomId, cb) =>
        room = @rooms.get roomId
        if room
          socket.join room.id
          cb?()
        else
          room = new @rooms.model id: roomId
          room.fetch success: (model) =>
            @rooms.add model
            socket.join model.id
            cb?()
          , error: =>
            throw new Error 'Room not find.'

    disconnect: (socket) ->
      socket.on 'disconnect', =>
        for key, value of socket.manager.roomClients[socket.id]
          socket.emit 'leaveRoom', key.slice 1

module.exports = AppController