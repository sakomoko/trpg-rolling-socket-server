should = require('should')
sinon = require('sinon')
mongoose = require('mongoose')

EventEmitter = require('events').EventEmitter
App = require '../lib/app-controller'
ObjectId = mongoose.Types.ObjectId

class Socket extends EventEmitter
  to: -> @
  set: ->
  join: ->

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
      sinon.spy @socket, 'emit'
      sinon.spy @socket, 'to'
      sinon.spy @socket, 'set'
      sinon.spy @socket, 'join'

    describe 'getRoomLog', ->
      beforeEach ->
        sinon.stub(@model, 'getBuffer').callsArgWith(0, [{},{}])
        @socket.emit 'getRoomLog', @model.id
      it 'rooms.getが呼ばれること', ->
        @stub.calledWith(@model.id).should.be.true
      it 'room.getBufferが呼ばれること', ->
        @model.getBuffer.called.should.be.true
      it 'pushMessageイベントが発火すること', ->
        @socket.emit.calledWith('pushMessage', @model.id, [{},{}]).should.be.true

    describe 'joinMember', ->
      beforeEach ->
        @request =
          id: 'id'
          name: 'UserName'
          socket_token: 'UserToken'
        sinon.stub(@model, 'joinMember').callsArgWith 2, @request
        sinon.stub(@model, 'getJoinedMembers').returns([@request])
        @socket.emit 'joinMember', @model.id, @request

      it 'rooms.getが呼ばれること', ->
        @stub.calledWith(@model.id).should.be.true

      it 'room.joinMemberが呼ばれること', ->
        @model.joinMember.calledWith(@socket, @request).should.be.true

      it 'successJoinedイベントが発火すること', ->
        @socket.emit.calledWith('successJoined', @model.id, @request).should.be.true

      it 'room.getJoinedMembersが呼ばれること', ->
        @model.getJoinedMembers.called.should.be.true

      it 'socketにsocket_tokenが書き込まれること', ->
        @socket.set.calledWith('socket_token', @request.socket_token).should.be.true

      it 'socket#joinが呼ばれること', ->
        @socket.join.calledWith(@model.id).should.be.true

      it '第三引数に渡したコールバックが呼ばれること',(done) ->
        @socket.emit 'joinMember', @model.id, @request, ->
          done()

      it '認証に失敗したらsocketFaildイベントを発火させること', ->
        @model.joinMember.throws(new Error('auth error!'))
        @socket.emit 'joinMember', @model.id, @request
        @socket.emit.calledWith('socketFaild', 'auth error!').should.be.true

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

      it 'メッセージはto(roomId)で配信されること', ->
        @socket.to.calledWith(@model.id).should.be.true

      describe '例外が発生したら', ->
        beforeEach ->
          @modelStub.throws(new Error('error!!'))
          @request = body: 'faild message'
          @socket.emit('sendMessage', @model.id, @request)
        it '例外メッセージを配信すること', ->
          @socket.emit.lastCall.calledWith('socketFaild', 'error!!').should.be.true
