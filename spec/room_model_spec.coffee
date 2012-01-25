ObjectId = require('mongodb').BSONPure.ObjectID
class User
  @find: () -> return
  @findOne: (key, callback) ->
    callback(false, {
      user_id: 'user_id_1'
      name: 'UserName'
    })

class Message
  @find: (key, options, sort, callback) ->
    callback(false, (new Document for num in [0...5]))
  save: (callback) ->
    callback(new Error("fail to save document."))
  toObject: () ->
    @

class Document
  toObject: () ->
    @
  created_at: new Date

class Client
  constructor: (@id = new ObjectId) ->
  leave: () ->
  emit: () ->
  broadcast: () ->
    @
  to: () ->
    @

RoomModel = require('../lib/room-model').RoomModel
mongoose = require "mongoose"
mongoose.connect('mongodb://localhost/test')

describe 'RoomModel', ->

  it 'インスタンスを作成したとき、@id, @messageがセットされていること', ->
    room = new RoomModel 'id', 'message'
    expect(room.id).toEqual('id')
    expect(room.message).toEqual('message')

  describe '#getBuffer', ->
    room = {}
    beforeEach ->
      room = new RoomModel 'id', Message, User
    it '渡したcallbackが実行されること', ->
      callback = jasmine.createSpy()
      room.getBuffer {}, callback
      expect(callback).toHaveBeenCalledWith({}, jasmine.any(Array))
    it 'Message#findが実行されること', ->
      spyOn Message, 'find'
      room.getBuffer()
      expect(Message.find).toHaveBeenCalledWith({room_id: 'id'}, {}, {sort:{_id:-1}, limit:50}, jasmine.any Function)
    it 'messageが得られなければfalseを返すこと', ->
      spyOn(Message, 'find').andReturn(null)
      room.getBuffer()
      expect(room.getBuffer()).toBeFalsy()

  describe "#dateFormat", ->
    it 'Dateクラスを与えるとフォーマット文字列に変換されること', ->
      room = new RoomModel 'id'
      expect(room.dateFormat(new Date "17 Jan 2012 14:52:15")).toEqual '2012-01-17 14:52:15'

  describe "#getJoinedMember", ->
    it 'clientからjoinしているmemberのデータを得られること', ->
      room = new RoomModel 'id'
      joined_member = {id: 'user_id', name: 'user_name', color: 'red'}
      client = new Client
      room.joinedMembers["#{client.id}"] = joined_member
      expect(room.getJoinedMember(client)).toEqual(joined_member)

  describe "#leaveMember", ->
    room = client = {}
    beforeEach ->
      room = new RoomModel 'id'
      client = new Client
      joined_member = {id: 'user_id', name: 'user_name', color: 'red'}
      room.joinedMembers["#{client.id}"] = joined_member

    it "clientを渡すと、clientがjoinedMembersから削除されること", ->
      room.leaveMember(client)
      expect(room.joinedMembers).toEqual({})

    it "client#leaveが実行されること", ->
      spyOn client, 'leave'
      room.leaveMember client
      expect(client.leave).toHaveBeenCalledWith(room.id)

    it "他の参加者に参加者一覧情報を配信すること", ->
      spyOn client, 'emit'
      spyOn(client, 'to').andCallThrough()
      spyOn(client, 'broadcast').andCallThrough()
      room.leaveMember client
      expect(client.emit).toHaveBeenCalledWith('updateJoinedMembers', room.id, {})
      expect(client.to).toHaveBeenCalledWith(room.id)
      expect(client.broadcast).toHaveBeenCalled()

  describe '#addBuffer', ->
    beforeEach ->
      @user_id = new ObjectId()
      @room = new RoomModel(new ObjectId)
      @client = new Client
      @data =
        body: 'hogehoge'
        dice: null
        alias: 'AliasName'
        supplement: null
      spyOn(User, 'findOne').andCallFake(=>
        args = User.findOne.mostRecentCall.args
        args[1](false, {
          id: @user_id
          name: 'UserName'
          color: 'UserColor'
        })
      )
      @room.user = User

    it 'documentが正常に保存されて、callbackに渡されること', ->
      callback = jasmine.createSpy()
      @room.addBuffer(@client, @data, callback)
      waits 50
      runs ->
        expect(callback).toHaveBeenCalledWith(jasmine.any(Object))
    it 'socket_tokenの照合に失敗したら例外がなげられること', ->
      User.findOne.andCallFake(->
        args = User.findOne.mostRecentCall.args
        args[1](false, null)
      )
      expect(=> @room.addBuffer(@client, @data)).toThrow(new Error("unmatched socket token."))
    it 'documentの保存に失敗したら例外が投げられること', ->
      spyOn(Message.prototype, 'save').andCallFake((callback)->
        callback(new Error("fail to save document."))
      )
      @data.body = null
      @room.message = Message
      callback = jasmine.createSpy()
      expect(=> @room.addBuffer(@client, @data, callback)).toThrow(new Error("fail to save document."))

    it 'documentにリファレンスのキーが含まれていること', ->
      callback = (doc) =>
        expect(doc.user_id.toString()).toEqual(@user_id.toString())
        expect(doc.room_id.toString()).toEqual(@room.id.toString())
        jasmine.asyncSpecDone()
      @room.addBuffer(@client, @data, callback)
      jasmine.asyncSpecWait()

    it 'documentを保存したときに、aliasが正しく設定されていること', ->
      callback = (doc) =>
        expect(doc.alias).toEqual('AliasName')
        jasmine.asyncSpecDone()
      @room.addBuffer(@client, @data, callback)
      jasmine.asyncSpecWait()

    it 'aliasが設定されていなければ、aliasにユーザー名がセットされていること', ->
      delete @data.alias
      callback = (doc) =>
        expect(doc.alias).toEqual('UserName')
        jasmine.asyncSpecDone()
      @room.addBuffer(@client, @data, callback)
      jasmine.asyncSpecWait()

  describe '#joinMember', ->
    beforeEach ->
      @user =
        id: new ObjectId
        name: 'UserName1'
        socket_token: 'socket_token1'
      @user2 =
        id: new ObjectId
        name: 'UserName2'
        socket_token: 'socket_token2'
      @client = new Client
      @client2 = new Client
      @room = new RoomModel(new ObjectId)
      @data =
        body: 'hogehoge'
        dice: null
        alias: 'AliasName'
        supplement: null
      @room.user = User

    it 'ユーザー名とユーザーIDからなるオブジェクトが、@joinedMembersに格納されること', ->
      @room.joinMember @client, @user
      expect(@room.joinedMembers[@client.id]).toEqual(@user)

    it '同じクライアントからの入室は無視すること', ->
      @room.joinMember @client, @user
      @room.joinMember @client, @user
      num = 0
      num++ for user of @room.joinedMembers
      expect(num).toEqual(1)

    it '複数のクライアントが格納できること', ->
      @room.joinMember @client, @user
      @room.joinMember @client2, @user2
      expect(@room.joinedMembers[@client.id]).toEqual(@user)
      expect(@room.joinedMembers[@client2.id]).toEqual(@user2)
      num = 0
      num++ for user of @room.joinedMembers
      expect(num).toEqual(2)

    it '必要な情報以外は格納しないこと', ->
      @user.hoge = 'huga'
      @user.fuga = 'hoge'
      @room.joinMember @client, @user
      expect(@room.joinedMembers[@client.id]).not.toEqual(@user)

    it 'ユーザー名が含まれていなければ、例外が発生すること', ->
      delete @user.name
      expect(=> @room.joinMember @client, @user).toThrow()
    it 'ユーザーIDが含まれていなければ、例外が発生すること', ->
      delete @user.id
      expect(=> @room.joinMember @client, @user).toThrow()

  it 'Connection closed.', ->
    mongoose.disconnect()