mongoose = require("mongoose")
Room = new mongoose.Schema
  title:
    type: String
    required: true

  is_static:
    type: Boolean
    required: true
    default: false

  is_closed:
    type: Boolean
    required: true
    default: false

  created:
    type: Date
    default: Date.now

mongoose.model "Room", Room
module.exports = mongoose.model "Room"
