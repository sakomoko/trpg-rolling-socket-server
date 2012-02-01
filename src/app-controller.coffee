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


module.exports = AppController