Rooms = require '../lib/room-collection'

describe 'ルーム一覧を取得したら', ->
  beforeEach ->
    @rooms = new Rooms()
  it 'イベントが発火すること', ->
    spyOn(@rooms.schema, 'find').andCallFake(=>
      args = @rooms.schema.find.mostRecentCall.args
      args[2](false, [{id: 11, title: 'room1'}])
    )
    @rooms.on('reset', ->
      expect(true).toBeTruthy()
      jasmine.asyncSpecDone()
    )
    jasmine.asyncSpecWait()
    @rooms.fetch()
