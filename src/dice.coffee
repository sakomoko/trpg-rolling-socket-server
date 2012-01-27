class Dice
  constructor: (@diceString) ->
    result = @diceString.match /^(\d+)d(\d+)?((\+|\-)(\d)+)?(\*(\d))?/i
    @num = result[1] - 0
    @type = result[2] - 0
    @bonus = (result[3] ? 0) - 0
    @rollCount = (result[7] ? 1) - 0
    @rollResult = []
    @rollResult.push @roll()

  roll: () ->
    result = (Math.floor(Math.random() * @type) + 1 for i in [1..@num])
    total = 0
    total+= value for value in result
    @result = total + @bonus
    dice_result:
      result
    dice_total:
      total
    bonus:
      @bonus
    result:
      @result

module.exports = Dice