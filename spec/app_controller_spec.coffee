EventEmitter = require('events').EventEmitter
ObjectId = require('mongodb').BSONPure.ObjectID
App = require '../lib/app-controller'

class Socket extends EventEmitter

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
    describe 'getJoinedMembers', ->
      beforeEach ->
        @socket = new Socket
        @app = new App
        @model = @app.rooms.create({id: new ObjectId().toString(), title: 'Room1'})
        @app.bindAllEvents @socket
        spyOn(@socket, 'emit').andCallThrough()
        spyOn(@app.rooms, 'get').andReturn(@model)
      it 'updateJoinedMembersイベントが発火すること', ->
        @socket.emit 'getJoinedMembers', @model.id
        expect(@socket.emit).toHaveBeenCalledWith('updateJoinedMembers', @model.id, [])