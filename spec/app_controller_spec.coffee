EventEmitter = require('events').EventEmitter
ObjectId = require('mongodb').BSONPure.ObjectID
App = require '../lib/app-controller'

class Socket extends EventEmitter
  to: -> @

describe 'AppController', ->

  describe '#bindAllEvents', ->
    it 'clientにイベントがバインドされること', ->
      @app = new App
      @socket = new Socket
      spyOn(@socket, 'on')
      @app.bindAllEvents @socket
      expect(@socket.on).toHaveBeenCalledWith('getRoomLog', jasmine.any(Function))
      expect(@socket.on).toHaveBeenCalledWith('joinMember', jasmine.any(Function))

  describe 'Events', ->
    beforeEach ->
      @socket = new Socket
      @app = new App
      @model = @app.rooms.create({id: new ObjectId().toString(), title: 'Room1'})
      spyOn(@socket, 'emit').andCallThrough()
      spyOn(@socket, 'on').andCallThrough()
      spyOn(@app.rooms, 'get').andReturn(@model)
      @app.bindAllEvents @socket

    describe 'getJoinedMembers', ->
      it 'updateJoinedMembersイベントが発火すること', ->
        @socket.emit 'getJoinedMembers', @model.id
        expect(@socket.emit).toHaveBeenCalledWith('updateJoinedMembers', @model.id, [])

    describe 'sendMessage', ->
      it 'sendMessageイベントがハンドルされること', ->
        expect(@socket.on).toHaveBeenCalledWith('sendMessage', jasmine.any Function)

      describe 'sendMessageイベントが発火したら', ->
        beforeEach ->
          spyOn(@model, 'addBuffer')
          @model.addBuffer.andCallFake =>
            args = @model.addBuffer.mostRecentCall.args
            args[2](@data)
          @data =
            body: 'This is test Message content'
          @socket.emit('sendMessage', @model.id, @data)

        it 'room#addBufferが呼ばれること', ->
          expect(@model.addBuffer).toHaveBeenCalledWith(@socket, @data, jasmine.any Function)
        it 'callback内でpushMessageイベントを発火させること', ->
          expect(@socket.emit).toHaveBeenCalledWith('pushMessage', @model.id, @data)

      describe '例外が発生したら', ->
        beforeEach ->
          spyOn(@model, 'addBuffer').andThrow(new Error('error!!'))
          @data = body: 'faild message'
          @socket.emit('sendMessage', @model.id, @data)
        it '例外メッセージを配信すること', ->
          expect(@socket.emit).toHaveBeenCalledWith('socketFaild', 'error!!')
