RoomCollection = require './room-collection'
class AppController
  rooms: new RoomCollection()

  bindAllEvents: (client) ->
    fn client for key, fn of @events

  events:
    getRoomLog: (client) =>
      client.on 'getRoomLog', (roomId) =>
        @rooms.get(roomId).getBuffer client, (client, docs)->
          client.emit 'pushMessage', roomId, docs


module.exports = AppController