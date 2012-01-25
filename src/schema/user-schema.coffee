mongoose = require("mongoose")
User = new mongoose.Schema
  name:
    type: String
    required: true

  socket_token:
    type: String
    required: true

mongoose.model "User", User
module.exports = mongoose.model "User"
