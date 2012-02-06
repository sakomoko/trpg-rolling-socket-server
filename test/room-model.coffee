require('should')
sinon = require('sinon')
mongoose = require('mongoose')
RoomModel = require('../lib/room-model')
Factory = require('factory-lady')
require('../support/factories')
ObjectId = require('mongodb').BSONPure.ObjectID
DatabaseCleaner = require('database-cleaner')
databaseCleaner = new DatabaseCleaner('mongodb')


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
      Factory.create 'room', (room) =>
        @roomId = room.id
        @room = new RoomModel id: @roomId, title: 'Room1'
        Factory.create 'message', (message) =>
          @message = message
          done()
    it '渡したcallbackが実行されること', (done) ->
      callback = (doc) ->
        done()
      @room.getBuffer {}, callback
    it 'callbackの引数に、messageのdocumentが配列で引き渡されること', (done) ->
      callback = (socket, docs) ->
        docs.should.be.an.instanceof Array
        done()
      @room.getBuffer {}, callback
    it '配列の内容が、Messageのオブジェクトであること'
    it '複数のメッセージが渡されること'
    it '部屋が見つからない場合は例外が発生すること'