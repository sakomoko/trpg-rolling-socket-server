should = require('should')
sinon = require('sinon')
EventEmitter = require('events').EventEmitter
RoomCollection = require '../lib/room-collection'
ObjectId = require('mongoose').Types.ObjectId

class Socket extends EventEmitter
  to: -> @
  set: ->
  join: ->

Socket::__defineGetter__ 'broadcast', ->
  @broadcasted = true
  @

describe 'RoomCollection', ->
  beforeEach (done) ->
    @rooms = new RoomCollection()
    @docs = [
      {id: 1, title: 'Room1'}
      {id: 2, title: 'Room2'}
    ]
    @schemaStub = sinon.stub(@rooms.schema, 'find').callsArgWith 2, false, @docs
    @rooms.fetch success: (docs) =>
      done()

  afterEach ->
    @schemaStub.restore()

  it 'モデルを複数取得できていること', ->
    @rooms.models.should.have.length 2

  describe 'getOpenRooms', ->
    it 'openされたRoomの一覧をobjectで取得できること', (done) ->
      @rooms.getOpenRooms (docs) =>
        (docs.every (doc)->
          !doc.closed_at
        ).should.be.true
        for obj in docs
          obj.should.be.an.instanceof Object
        done()