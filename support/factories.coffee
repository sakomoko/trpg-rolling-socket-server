uuid = require('node-uuid')
Factory = require('factory-lady')
User = require('../lib/schema/user-schema')
Room = require('../lib/schema/room-schema')
Message = require('../lib/schema/message-schema')

emailCounter = 1
nameCounter = 1

Factory.define 'user', User,
  email: (cb) -> cb("user#{emailCounter++}@example.com")
  name: (cb) -> cb("user#{nameCounter}")
  socket_token: (cb) -> cb(uuid.v4())

Factory.define 'room', Room,
  title: 'RoomName'
  static: false

Factory.define 'message', Message,
  room_id: Factory.assoc 'room', 'id'
  user_id: Factory.assoc 'user', 'id'
  body: 'Message content.'
  alias: 'UserAliasName'
