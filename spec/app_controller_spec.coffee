App = require '../lib/app-controller'

class Client
  on: () ->

describe 'AppController', ->

  describe '#bindAllEvents', ->
    it 'clientにイベントがバインドされること', ->
      @app = new App
      @client = new Client
      spyOn(@client, 'on')
      @app.bindAllEvents @client
      expect(@client.on).toHaveBeenCalledWith('getRoomLog', jasmine.any(Function))

