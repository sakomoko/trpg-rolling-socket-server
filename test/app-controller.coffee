should = require('should')
sinon = require('sinon')
mongoose = require('mongoose')

EventEmitter = require('events').EventEmitter
App = require '../lib/app-controller'
ObjectId = mongoose.Types.ObjectId

class Socket extends EventEmitter
  to: -> @

describe 'AppController', ->

  describe '#bindAllEvents', ->
    it 'イベントの数だけ、socketにイベントがバインドされること', ->
      @app = new App
      @socket = new Socket
      @spy = sinon.spy(@socket, 'on')
      @app.bindAllEvents @socket
      @spy.callCount.should.have.equal Object.keys(@app.events).length
      for key in Object.keys(@app.events)
        @spy.calledWith(key).should.be.true

  describe 'Events', ->
    beforeEach ->
      @socket = new Socket
      @app = new App
      @model = @app.rooms.create({id: new ObjectId(), title: 'Room1'})
      @stub = sinon.stub(@app.rooms, 'get').returns(@model)
      @app.bindAllEvents @socket
      @spy = sinon.spy @socket, 'emit'

    describe 'getJoinedMembers', ->
      it 'updateJoinedMembersイベントが発火すること', ->
        @socket.emit 'getJoinedMembers', @model.id
        @socket.emit.calledWith('updateJoinedMembers', @model.id, []).should.be.true

    describe 'sendMessage', ->
      beforeEach ->
        @modelStub = sinon.stub(@model, 'addBuffer')
        @request =
          body: 'This is test Message content'
        @model.addBuffer.callsArgWith 2, @request
        @socket.emit 'sendMessage', @model.id, @request

      it 'room#addBufferが呼ばれること', ->
        @model.addBuffer.calledWith(@socket, @request).should.be.true

      it 'callback内でpushMessageイベントを発火させること', ->
        @socket.emit.secondCall.calledWith('pushMessage', @model.id, @request).should.be.true

      describe '例外が発生したら', ->
        beforeEach ->
          @modelStub.throws(new Error('error!!'))
          @request = body: 'faild message'
          @socket.emit('sendMessage', @model.id, @request)
        it '例外メッセージを配信すること', ->
          @spy.lastCall.calledWith('socketFaild', 'error!!').should.be.true
