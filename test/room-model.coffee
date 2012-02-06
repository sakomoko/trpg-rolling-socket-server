require('should')
async = require('async')
sinon = require('sinon')
mongoose = require('mongoose')
RoomModel = require('../lib/room-model')
Factory = require('factory-lady')
require('../support/factories')
ObjectId = require('mongodb').BSONPure.ObjectID
DatabaseCleaner = require('database-cleaner')
databaseCleaner = new DatabaseCleaner('mongodb')

ObjectId = mongoose.Types.ObjectId;

createMessage = (roomId, callback) ->

describe 'RoomModel', ->
  before (done) =>
    mongoose.connect('mongodb://localhost/trpg_rolling_test', -> done())
  after (done) =>
    databaseCleaner.clean mongoose.connection.db, -> done()

  describe 'インスタンスを作成したとき', ->
    beforeEach ->
      @roomId = new ObjectId().toString()
      @room = new RoomModel id: @roomId, title: 'Room1'
    it 'should have propety id', ->
      @room.should.have.property('id', @roomId)
    it 'should have title equal Room1', ->
      @room.get('title').should.equal('Room1')

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
