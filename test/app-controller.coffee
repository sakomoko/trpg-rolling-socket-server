should = require('should')
sinon = require('sinon')
mongoose = require('mongoose')

EventEmitter = require('events').EventEmitter
App = require '../lib/app-controller'
ObjectId = mongoose.Types.ObjectId

class Socket extends EventEmitter
  constructor: (@id = new ObjectId)->
  to: -> @
  set: ->
  join: ->

Socket::__defineGetter__ 'broadcast', ->
  @broadcasted = true
  @

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
      @stub = sinon.stub(@app.rooms, 'get').withArgs(@model.id).returns(@model)
      @app.bindAllEvents @socket
      sinon.spy @socket, 'emit'
      sinon.spy @socket, 'to'
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
        sinon.stub @socket, 'set'
        @socket.set.callsArg(2)
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

    describe 'sendTypingStatus', ->
      beforeEach ->
        user =
          id: 'UserId'
          alias: 'UserAlias'
        sinon.stub(@model, 'getJoinedMember').returns user
        @socket.emit 'sendTypingStatus', @model.id, true

      it 'model.getJoinedMemberが呼ばれること', ->
        @model.getJoinedMember.calledWith(@socket).should.be.true

      it 'socket#broadcastが呼ばれること', ->
        @socket.broadcasted.should.be.true

      it 'socket#toが呼ばれること', ->
        @socket.to.calledWith(@model.id).should.be.true

      it 'pushTypingStatusイベントが発火されること', ->
        @socket.emit.calledWith('pushTypingStatus').should.be.true

      it 'pushTypingStatusにroomIdと通知者のid,aliasのオブジェクト、isTypingの真偽値が渡されること', ->
        user =
          id: 'UserId'
          alias: 'UserAlias'
        @socket.emit.calledWith('pushTypingStatus', @model.id, user, true).should.be.true

      it 'ユーザー情報が取得できなかったらsocketFaildを発火させること', ->
        @model.getJoinedMember.returns undefined
        @socket.emit 'sendTypingStatus', @model.id, true
        @socket.emit.calledWith('socketFaild').should.be.true

    describe 'getRoomList', ->
      beforeEach ->
        @joinedRoom = @app.rooms.create id: new ObjectId, title: 'JoinedRoom'
        @joinedRoom.joinedMembers[@socket.id] = true
        @roomList = [
          {id: @model.id, title: @model.get('title')}
          {id: 'room1', title: 'Room1'}
          {id: 'room2', title: 'Room2'}
          {id: 'room3', title: 'Room3'}
          {id: @joinedRoom.id, title: @joinedRoom.get('title')}
        ]
        @app.rooms.get.withArgs(@joinedRoom.id).returns @joinedRoom
        sinon.stub(@app.rooms, 'getOpenRooms').callsArgWith 0, @roomList
        @socket.emit 'getRoomList'

      it 'rooms.getOpenRoomsが呼ばれること', ->
        @app.rooms.getOpenRooms.called.should.be.true

      it 'pushRoomListが発火すること', ->
        @socket.emit.getCall(1).calledWith('pushRoomList').should.be.true

      it '自分が入室している部屋は除外されていること', ->
        @roomList.pop()
        @socket.emit.getCall(1).calledWithExactly('pushRoomList', @roomList).should.be.true