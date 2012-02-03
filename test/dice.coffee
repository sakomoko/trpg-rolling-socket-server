require('should')
sinon = require('sinon')
Dice = require ('../lib/dice')

describe 'Dice', ->
  describe '#constructor', ->
    beforeEach ->
      sinon.stub(Math, 'random').returns(0.35)
    afterEach ->
        Math.random.restore()

    describe 'typeにdice文字列"2d6"を指定したとき', ->
      beforeEach ->
        @dice = new Dice("2d6")

      it 'randメソッドが二度呼ばれること', ->
        Math.random.callCount.should.equal(2)
      it 'numが2を返すこと', ->
        @dice.num.should.equal(2)
      it 'typeが6を返すこと', ->
        @dice.type.should.equal(6)
      it 'bonusが0を返すこと', ->
        @dice.bonus.should.equal(0)
      it 'rollCountが１を返すこと', ->
        @dice.rollCount.should.equal(1)
      it 'diceStringがダイス文字列を返すこと', ->
        @dice.diceString.should.equal("2d6")
      it 'rollResultが結果配列を返すこと', ->
        @dice.rollResult.should.eql([
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
        @dice.result.should.equal(6)

    describe 'typeにdice文字列"2d6+5"を指定したとき', ->

      beforeEach ->
        @dice = new Dice("2d6+5")

      it 'randメソッドが二度呼ばれること', ->
        Math.random.callCount.should.equal 2
      it 'numが2を返すこと', ->
        @dice.num.should.equal 2
      it 'typeが6を返すこと', ->
        @dice.type.should.equal(6)
      it 'bonusが5を返すこと', ->
        @dice.bonus.should.equal(5)
      it 'rollCountが１を返すこと', ->
        @dice.rollCount.should.equal(1)
      it 'diceStringがダイス文字列を返すこと', ->
        @dice.diceString.should.equal("2d6+5")
      it 'rollResultが結果配列を返すこと', ->
        @dice.rollResult.should.eql([
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
        @dice.result.should.equal(11)

    describe 'typeにdice文字列"3d7+12"を指定したとき', ->
      beforeEach ->
        @dice = new Dice("3d7+12")

      it 'randメソッドが3度呼ばれること', ->
        Math.random.callCount.should.equal(3)
      it 'numが3を返すこと', ->
        @dice.num.should.equal(3)
      it 'typeが7を返すこと', ->
        @dice.type.should.equal(7)
      it 'bonusが12を返すこと', ->
        @dice.bonus.should.equal(12)
      it 'rollCountが１を返すこと', ->
        @dice.rollCount.should.equal(1)
      it 'diceStringがダイス文字列を返すこと', ->
        @dice.diceString.should.equal("3d7+12")
      it 'rollResultが結果配列を返すこと', ->
        @dice.rollResult.should.eql([
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
        @dice.result.should.equal(21)

    describe 'typeにdice文字列"2d6*2"を指定したとき', ->
      beforeEach ->
        @dice = new Dice("2d6*2")

      it 'randメソッドが4度呼ばれること', ->
        Math.random.callCount.should.equal(4)
      it 'numが2を返すこと', ->
        @dice.num.should.equal(2)
      it 'typeが6を返すこと', ->
        @dice.type.should.equal(6)
      it 'rollCountが2を返すこと', ->
        @dice.rollCount.should.equal(2)
      it 'diceStringがダイス文字列を返すこと', ->
        @dice.diceString.should.equal("2d6*2")
      it 'resultが配列を返すこと', ->
        @dice.result.should.eql([6,6])

    describe 'typeにdice文字列"100d100+100*100"を指定したとき', ->
      beforeEach ->
        @dice = new Dice("100d100+100*100")
      it 'randメソッドが10000回呼ばれること', ->
        Math.random.callCount.should.equal(10000)
      it 'numが100を返すこと', ->
        @dice.num.should.equal(100)
      it 'typeが100を返すこと', ->
        @dice.type.should.equal(100)
      it 'rollCountが100を返すこと', ->
        @dice.rollCount.should.equal(100)
      it 'diceStringがダイス文字列を返すこと', ->
        @dice.diceString.should.equal("100d100+100*100")
      it 'resultが配列を返すこと', ->
        @dice.result.length.should.equal(100)


  describe '::searchString', ->
    it '行末にダイス文字列があれば、それを返すこと', ->
      @string = 'hogehoge2d6'
      Dice.searchString(@string).should.equal('2d6')
      @string = 'hogehoge2d6-5'
      Dice.searchString(@string).should.equal('2d6-5')
      @string = 'hogehoge2d100'
      Dice.searchString(@string).should.equal('2d100')
      @string = 'hogehoge10d10*10'
      Dice.searchString(@string).should.equal('10d10*10')
      @string = 'hogehoge100d100+100*100'
      Dice.searchString(@string).should.equal('100d100+100*100')
      @string = """
        This is
        test message
        3d6

        """
      Dice.searchString(@string).should.equal('3d6')
      @string = '2d6'
      Dice.searchString(@string).should.equal('2d6')
    it '文中のダイス文字列は無視すること', ->
      @string = 'hogehoge2d6hogehoge'
      Dice.searchString(@string).should.be.false
      @string = '2d6を振って下さい'
      Dice.searchString(@string).should.be.false

    it 'ダイス文字列がなければ、falseを返すこと', ->
      @string = '2hdog6e7'
      Dice.searchString(@string).should.be.false

  describe '::removeString', ->
    it '文末のダイス文字列を削除する', ->
      @string = """
        2d6を振って下さい
        2d6

        """
      expected = """
        2d6を振って下さい


        """
      Dice.removeString(@string).should.equal expected
    it 'ダイス文字列だけの場合は削除しない', ->
      @string = '2d6'
      Dice.removeString(@string).should.equal '2d6'
    it '文中のダイス文字列は削除しない', ->
      @string = """
        そうですねえ、2d6にしましょうかねえ。
        どうだろう。2d6でいいなぁ。

        """
      Dice.removeString(@string).should.equal @string
