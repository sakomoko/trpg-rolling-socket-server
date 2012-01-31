Dice = require '../lib/dice'
describe 'Dice', ->
  describe '#constructor', ->

    describe 'typeにdice文字列"2d6"を指定したとき', ->
      beforeEach ->
        spyOn(Math, 'random').andReturn(0.35)
        @dice = new Dice("2d6")
      it 'randメソッドが二度呼ばれること', ->
        expect(Math.random.callCount).toEqual(2)
      it 'numが2を返すこと', ->
        expect(@dice.num).toEqual(2)
      it 'typeが6を返すこと', ->
        expect(@dice.type).toEqual(6)
      it 'bonusが0を返すこと', ->
        expect(@dice.bonus).toEqual(0)
      it 'rollCountが１を返すこと', ->
        expect(@dice.rollCount).toEqual(1)
      it 'diceStringがダイス文字列を返すこと', ->
        expect(@dice.diceString).toEqual("2d6")
      it 'rollResultが結果配列を返すこと', ->
        expect(@dice.rollResult).toEqual([
          {
            dice_result:
              [3, 3]
            dice_total:
              6
            bonus:
              0
            result:
              6
            type:
              6
          }
        ])
      it 'resultが合計値の6を返すこと', ->
        expect(@dice.result).toEqual(6)

    describe 'typeにdice文字列"2d6+5"を指定したとき', ->
      beforeEach ->
        spyOn(Math, 'random').andReturn(0.35)
        @dice = new Dice("2d6+5")
      it 'randメソッドが二度呼ばれること', ->
        expect(Math.random.callCount).toEqual(2)
      it 'numが2を返すこと', ->
        expect(@dice.num).toEqual(2)
      it 'typeが6を返すこと', ->
        expect(@dice.type).toEqual(6)
      it 'bonusが5を返すこと', ->
        expect(@dice.bonus).toEqual(5)
      it 'rollCountが１を返すこと', ->
        expect(@dice.rollCount).toEqual(1)
      it 'diceStringがダイス文字列を返すこと', ->
        expect(@dice.diceString).toEqual("2d6+5")
      it 'rollResultが結果配列を返すこと', ->
        expect(@dice.rollResult).toEqual([
          {
            dice_result:
              [3, 3]
            dice_total:
              6
            bonus:
              5
            result:
              11
            type:
              6
          }
        ])
      it 'resultが合計値の11を返すこと', ->
        expect(@dice.result).toEqual(11)

    describe 'typeにdice文字列"3d7+12"を指定したとき', ->
      beforeEach ->
        spyOn(Math, 'random').andReturn(0.35)
        @dice = new Dice("3d7+12")
      it 'randメソッドが3度呼ばれること', ->
        expect(Math.random.callCount).toEqual(3)
      it 'numが3を返すこと', ->
        expect(@dice.num).toEqual(3)
      it 'typeが7を返すこと', ->
        expect(@dice.type).toEqual(7)
      it 'bonusが12を返すこと', ->
        expect(@dice.bonus).toEqual(12)
      it 'rollCountが１を返すこと', ->
        expect(@dice.rollCount).toEqual(1)
      it 'diceStringがダイス文字列を返すこと', ->
        expect(@dice.diceString).toEqual("3d7+12")
      it 'rollResultが結果配列を返すこと', ->
        expect(@dice.rollResult).toEqual([
          {
            dice_result:
              [3, 3, 3]
            dice_total:
              9
            bonus:
              12
            result:
              21
            type:
              7
          }
        ])
      it 'resultが合計値の11を返すこと', ->
        expect(@dice.result).toEqual(21)

    describe 'typeにdice文字列"2d6*2"を指定したとき', ->
      beforeEach ->
        spyOn(Math, 'random').andReturn(0.35)
        @dice = new Dice("2d6*2")
      it 'randメソッドが4度呼ばれること', ->
        expect(Math.random.callCount).toEqual(4)
      it 'numが2を返すこと', ->
        expect(@dice.num).toEqual(2)
      it 'typeが6を返すこと', ->
        expect(@dice.type).toEqual(6)
      it 'rollCountが2を返すこと', ->
        expect(@dice.rollCount).toEqual(2)
      it 'diceStringがダイス文字列を返すこと', ->
        expect(@dice.diceString).toEqual("2d6*2")
      it 'resultが配列を返すこと', ->
        expect(@dice.result).toEqual([6,6])

    describe 'typeにdice文字列"100d100+100*100"を指定したとき', ->
      beforeEach ->
        spyOn(Math, 'random').andReturn(0.35)
        @dice = new Dice("100d100+100*100")
      it 'randメソッドが10000回呼ばれること', ->
        expect(Math.random.callCount).toEqual(10000)
      it 'numが100を返すこと', ->
        expect(@dice.num).toEqual(100)
      it 'typeが100を返すこと', ->
        expect(@dice.type).toEqual(100)
      it 'rollCountが100を返すこと', ->
        expect(@dice.rollCount).toEqual(100)
      it 'diceStringがダイス文字列を返すこと', ->
        expect(@dice.diceString).toEqual("100d100+100*100")
      it 'resultが配列を返すこと', ->
        expect(@dice.result.length).toEqual(100)


  describe '::searchString', ->
    it '行末にダイス文字列があれば、それを返すこと', ->
      @string = 'hogehoge2d6'
      expect(Dice.searchString @string).toEqual('2d6')
      @string = 'hogehoge2d6-5'
      expect(Dice.searchString @string).toEqual('2d6-5')
      @string = 'hogehoge2d100'
      expect(Dice.searchString @string).toEqual('2d100')
      @string = 'hogehoge10d10*10'
      expect(Dice.searchString @string).toEqual('10d10*10')
      @string = 'hogehoge100d100+100*100'
      expect(Dice.searchString @string).toEqual('100d100+100*100')
      @string = """
        This is
        test message
        3d6

        """
      expect(Dice.searchString @string).toEqual('3d6')
      @string = '2d6'
      expect(Dice.searchString @string).toEqual('2d6')
    it '文中のダイス文字列は無視すること', ->
      @string = 'hogehoge2d6hogehoge'
      expect(Dice.searchString @string).toBeFalsy()
      @string = '2d6を振って下さい'
      expect(Dice.searchString @string).toBeFalsy()

    it 'ダイス文字列がなければ、falseを返すこと', ->
      @string = '2hdog6e7'
      expect(Dice.searchString @string).toBeFalsy()