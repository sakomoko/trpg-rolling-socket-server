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
