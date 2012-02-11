var Room, mongoose;

mongoose = require("mongoose");

Room = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  static: {
    type: Boolean,
    required: true,
    "default": false
  },
  closed: {
    type: Boolean,
    "default": false
  },
  created_at: {
    type: Date,
    "default": Date.now
  },
  closed_at: {
    type: Date
  }
});

mongoose.model("Room", Room);

module.exports = mongoose.model("Room");
