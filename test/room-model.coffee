require('should')
async = require('async')
sinon = require('sinon')
uuid = require('node-uuid')
mongoose = require('mongoose')
RoomModel = require('../lib/room-model')
Factory = require('factory-lady')
require('../support/factories')
DatabaseCleaner = require('database-cleaner')
databaseCleaner = new DatabaseCleaner('mongodb')

ObjectId = mongoose.Types.ObjectId;

class Socket
  constructor: (@id = new ObjectId) ->
  join: ->
  to: -> @
  emit: ->
  leave: ->
  get: ->

Socket::__defineGetter__ 'broadcast', -> @

class MessageStub
  save: ->

class SchemaStub
  save: ->

describe 'RoomModel', ->
  before (done) =>
    mongoose.connect('mongodb://localhost/trpg_rolling_test', -> done())
  after (done) =>
    databaseCleaner.clean mongoose.connection.db, -> done()

  beforeEach ->
    @room = new RoomModel id: new ObjectId
    @socket = new Socket

  describe 'ObjectIdからインスタンスを作成したとき', ->
    beforeEach ->
      @roomId = new ObjectId
      @room = new RoomModel id: @roomId, title: 'Room1'

    it 'ObjectIdを文字列としたものをidとして持っていること', ->
      @room.should.have.property('id', @roomId.toString())

    it 'ObjectIdオブジェクトを_idプロパティに持っていること', ->
      @room.get('_id').should.equal @roomId

    it 'should have title equal Room1', ->
      @room.get('title').should.equal('Room1')

  describe 'ObjectIdの文字列からインスタンスを作成したとき', ->
    beforeEach ->
      @roomId = new ObjectId
      @room = new RoomModel id: @roomId.toString(), title: 'Room1'

    it 'ObjectIdを文字列としたものをidとして持っていること', ->
      @room.should.have.property('id', @roomId.toString())

    it 'ObjectIdオブジェクトを_idプロパティに持っていること', ->
      @room.get('_id').should.eql @roomId
      @room.get('_id').should.be.an.instanceof ObjectId

  describe '#addBuffer', ->
    beforeEach ->
      @doc =
        id: new ObjectId
        name: 'UserName'
      @userStub = sinon.stub(@room.user, 'findOne').callsArgWith 1, false, @doc
      @request =
        alias: 'AliasName'
        socket_token: 'uuid_token'
        body: 'text'
      sinon.stub(@socket, 'get').callsArgWith(1, false, 'stored_token')
    afterEach ->
      @userStub.restore()
      @messageStub?.restore()

    it 'socket#getが呼ばれること', (done) ->
      @room.addBuffer @socket, @request, =>
        @socket.get.calledWith('socket_token').should.be.true
        done()

    it 'socket_tokenの取得に失敗したら例外が発生すること', ->
      @socket.get.callsArgWith(1, true, 'stored_token')
      (=> @room.addBuffer @socket, @request).should.throw()

    it 'socket_tokenの取得に失敗したら例外が発生すること', ->
      @socket.get.callsArgWith(1, false, '')
      (=> @room.addBuffer @socket, @request).should.throw()

    it 'User#findOneが呼ばれること', (done) ->
      @room.addBuffer @socket, @request, =>
        @userStub.called.should.be.true
        done()

    it 'callbackが呼ばれること', (done) ->
      @room.addBuffer @socket, @request, =>
        done()

    it 'documentが正常に保存されて、callbackに渡されること', (done) ->
      @room.addBuffer @socket, @request, (doc) =>
        doc.should.exist
        done()

    it 'socket_tokenの照合に失敗したら例外がなげられること', ->
      @userStub.callsArgWith 1, false, null
      (=> @room.addBuffer @socket, @request).should.throw()

    it 'documentの保存に失敗したら例外が投げられること', ->
      @messageStub = sinon.stub(MessageStub::, 'save').callsArgWith 0, true
      @room.message = MessageStub
      (=> @room.addBuffer @socket, @request).should.throw()

    it 'documentにリファレンスのキーが含まれていること', (done) ->
      @room.addBuffer @socket, @request, (doc) =>
        doc.should.have.property('user_id').with.eql @doc.id
        doc.should.have.property('room_id').with.eql @room.get('_id')
        done()

    it 'documentを保存したときに、リクエストにあるaliasが正しく設定されていること', (done) ->
      @room.addBuffer @socket, @request, (doc) =>
        doc.should.have.property('alias').with.equal @request.alias
        done()

    it 'aliasが指定されていなければ、aliasにユーザー名がセットされていること', (done) ->
      delete @request.alias
      @room.addBuffer @socket, @request, (doc) =>
        doc.should.have.property('alias').with.equal @doc.name
        done()

    it '行末にdice文字列が含まれていれば、document.diceにダイスロールの結果が格納されること', (done) ->
      @request.body = 'hogehoge2d6'
      @room.addBuffer @socket, @request, (doc) =>
        doc.should.have.property('dice').with.length 1
        done()


  describe '#getBuffer', ->
    beforeEach (done) ->
      @messageIds = []
      async.series([
        (callback) =>
          Factory.create 'room',  (room) =>
            @roomId = room.id
            @room = new RoomModel id: @roomId, title: 'Room1'
            callback()

        (callback) =>
          async.forEach(
            [0..4],
            (item, cb) =>
              Factory.create 'message', room_id: @roomId, (message) =>
                @messageIds.push message.id
                cb()
            () -> callback()
          )

        (calllback) =>
          done()
      ])

    it '渡したcallbackが実行されること', (done) ->
      callback = (doc) ->
        done()
      @room.getBuffer callback
    it 'callbackの引数に、messageのdocumentが配列で引き渡されること', (done) ->
      callback = (docs) ->
        docs.should.be.an.instanceof Array
        done()
      @room.getBuffer callback
    it '配列の内容がオブジェクトであること', (done) ->
      callback = (docs) ->
        document = docs[0]
        document.should.be.a 'object'
        done()
      @room.getBuffer callback
    it 'オブジェクトがプロパティを持っていること', (done) ->
      callback = (docs) ->
        document = docs[0]
        document.should.have.property('id').with.not.empty
        document.should.have.property('_id').with.instanceof ObjectId
        document.should.have.property('user_id').with.should.not.empty
        document.should.have.property 'alias', 'UserAliasName'
        document.should.have.property 'body', 'Message content.'
        document.should.have.property('dice').with.instanceof(Array)
        document.should.have.property 'created_at'
        done()
      @room.getBuffer callback
    it '複数のメッセージが渡されること', (done) ->
      callback = (docs) ->
        docs.should.have.length 5
        done()
      @room.getBuffer callback
    it 'メッセージが見つからない場合は空配列を返すこと', (done) ->
      @room = new RoomModel id: new ObjectId
      callback = (docs) ->
        docs.should.be.an.instanceof Array
        docs.should.be.empty
        done()
      @room.getBuffer callback
    it 'エラーがあった場合は例外が発生すること', ->
      sinon.stub(@room.message, 'find').callsArgWith(3, true, null)
      (=> @room.getBuffer()).should.throw()

  describe '#getJoinedMember', ->
    beforeEach () ->
      @socketId = @socket.id = new ObjectId.toString()
      @userId = new ObjectId
      @data = @room.joinedMembers[@socketId] =
        id: @userId
        name: 'joinedName'
    it 'socketを渡すと、joinした際のデータを得られること', ->
      @room.getJoinedMember(@socket).should.eql @data
    it 'データがなければfalseを返すこと', ->
      @socket.id = new ObjectId
      @room.getJoinedMember(@socket).should.be.false

  describe '#getJoinedMembers', ->

    it '入室者のデータを配列で得られること', ->
      @room.getJoinedMembers().should.be.an.instanceof Array

    it '三人が入室していれば、三人のデータが得られること', ->
      for i in [1..3]
        @room.joinedMembers[i] =
          name: "User#{i}"
          color: "UserColor#{i}"
      @room.getJoinedMembers().should.have.length 3

  describe '#joinMember', ->
    beforeEach (done) ->
      @socket = new Socket
      @socket2 = new Socket
      @socketId = @socket.id = new ObjectId.toString()

      Factory.create 'user', (user) =>
        @userId = user.id
        @userRequest =
          id: user.id
          name: user.name
          alias: 'AliasName'
          socket_token: user.socket_token
        @spy = sinon.stub(@room.user, 'findOne').callsArgWith(1, false, user)
        done()

      @userRequest2 =
        id: new ObjectId
        name: 'UserName2'
        socket_token: uuid.v4()

    afterEach ->
      @room.user.findOne.restore()

    it 'ユーザー名とユーザーIDからなるオブジェクトが、@joinedMembersに格納されること',  ->
      @room.joinMember @socket, @userRequest
      delete @userRequest.socket_token
      @room.joinedMembers[@socket.id].should.eql @userRequest

    it '同じクライアントからの入室は無視すること', ->
      @room.joinMember @socket, @userRequest
      @room.joinMember @socket, @userRequest
      num = 0
      num++ for user of @room.joinedMembers
      Object.keys(@room.joinedMembers).should.have.length 1

    it '複数のクライアントが格納できること', ->
      @room.joinMember @socket, @userRequest
      @room.user.findOne.callsArgWith(1, false, @userRequest2)
      @room.joinMember @socket2, @userRequest2
      delete @userRequest.socket_token
      delete @userRequest2.socket_token
      @room.joinedMembers[@socket.id].should.eql @userRequest
      @room.joinedMembers[@socket2.id].should.eql @userRequest2
      Object.keys(@room.joinedMembers).should.have.length 2


    it '必要な情報以外は格納しないこと', ->
      @userRequest.hoge = 'huga'
      @userRequest.fuga = 'hoge'
      @room.joinMember @socket, @userRequest
      @room.joinedMembers[@socket.id].should.not.eql @userRequest

    it 'ユーザー名が含まれていなければ、例外が発生すること', ->
      delete @userRequest.name
      (=> @room.joinMember @socket, @user).should.throw()
    it 'ユーザーIDが含まれていなければ、例外が発生すること', ->
      delete @userRequest.id
      (=> @room.joinMember @socket, @userRequest).should.throw()

    it 'socket_tokenが含まれていなければ、例外が発生すること', ->
      delete @userRequest.socket_token
      (=> @room.joinMember @socket, @userRequest).should.throw()

    it 'ユーザーidとsocket_tokenで認証を行うこと', ->
      @room.joinMember @socket, @userRequest
      @spy.calledWith({id: @userRequest.id, socket_token: @userRequest.socket_token}).should.be.true

    it 'ユーザー名とsocket_tokenが一致しなければ、例外が発生すること', ->
      @room.user.findOne.callsArgWith(1, false, null)
      (=> @room.joinMember @socket, @userRequest).should.throw()

    it '渡したコールバックが実行されること', (done) ->
      @room.joinMember @socket, @userRequest, =>
        done()

  describe '#leaveMember', ->
    beforeEach ->
      @room.joinedMembers[@socket.id] = @socket

    it "socketを渡すと、socketがjoinedMembersから削除されること", ->
      @room.leaveMember(@socket)
      @room.joinedMembers.should.eql {}


  describe 'Roomを新規作成して保存したとき', ->
    beforeEach ->
      @room = new RoomModel title: 'Room1'

    it '#schema.saveが呼ばれること', ->
      @room.schema = SchemaStub
      spy = sinon.spy(SchemaStub::, 'save')
      @room.save(title: 'Room1')
      spy.called.should.be.true
      spy.restore()

    it 'モデルを渡したcallbackが呼ばれること', (done) ->
      @room.save(null, success: (doc) ->
        doc.should.be.an.instanceof RoomModel
        done()
      )

    it 'idが文字列でセットされていること', (done) ->
      @room.save(null, success: (doc) ->
        doc.should.have.property('id').with.be.not.empty
        done()
      )

    it 'attributes._idにObjectIdがセットされていること', (done) ->
      @room.save(null, success: (doc) ->
        doc.attributes.should.have.property('_id')
        doc.get("_id").should.be.an.instanceof ObjectId
        done()
      )

  describe '既存のRoomに変更を加えて保存したとき', ->
    beforeEach (done) ->
      Factory.create 'room', (room) =>
        @room = new RoomModel(room.toObject())
        @roomId = @room.id
        @room.set('title', 'ChangeTitle')
        done()

    it '正しく保存が行われていること', (done) ->
      @room.save null, success: (model) =>
        model.should.equal @room
        model.should.have.property('id').with.equal @roomId
        model.get('title').should.equal('ChangeTitle')
        done()

    it 'idにObjectId文字列があること', (done) ->
      @room.save null, success: (model) =>
        model.id.should.be.a 'string'
        model.get('_id').equals(model.id).should.be.true
        done()

    it 'idにObjectIdがあること', (done) ->
      @room.save null, success: (model) =>
        model.get('_id').toString().should.equal model.id
        model.get('_id').should.be.an.instanceof ObjectId
        done()