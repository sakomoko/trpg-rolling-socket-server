var Room, mongoose;

mongoose = require("mongoose");

Room = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  is_static: {
    type: Number,
    required: true,
    "default": 0
  },
  is_closed: {
    type: Number,
    required: true,
    "default": 0
  },
  created: {
    type: Date,
    "default": Date.now
  }
});

mongoose.model("Room", Room);

if (typeof exports === "undefined" || exports === null) {
  exports = mongoose.model("Room");
}
