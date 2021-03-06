var Message, ObjectId, Schema, mongoose;

mongoose = require("mongoose");

Schema = mongoose.Schema;

ObjectId = Schema.ObjectId;

Message = new Schema({
  room_id: {
    type: ObjectId,
    required: true,
    index: true
  },
  user_id: {
    type: ObjectId,
    required: true,
    index: true,
    ref: 'User'
  },
  color: {
    type: String
  },
  body: {
    type: String,
    required: true
  },
  dice: {
    type: Array
  },
  alias: {
    type: String,
    required: true
  },
  supplement: {
    type: String
  },
  created_at: {
    type: Date,
    "default": Date.now
  }
});

mongoose.model("Message", Message);

module.exports = mongoose.model("Message");
