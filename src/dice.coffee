class Dice
  @pattern:
    /\d{1,3}d\d{1,3}((\+|\-)\d+)?(\*\d+)?$/im

  constructor: (@diceString) ->
    result = @diceString.match /^(\d+)d(\d+)?((\+|\-)(\d)+)?(\*(\d+))?/i
    @num = result[1] - 0
    @type = result[2] - 0
    @bonus = (result[3] ? 0) - 0
    @rollCount = (result[7] ? 1) - 0
    @result = if @rollCount > 1 then new Array else 0
    @rollResult = []
    @rollResult.push @roll() for i in [1..@rollCount]


  roll: () ->
    dice_result = (Math.floor(Math.random() * @type) + 1 for i in [1..@num])
    dice_total = 0
    dice_total+= value for value in dice_result
    result = dice_total + @bonus
    if @result instanceof Array
      @result.push result
    else
      @result = result

    dice_result:
      dice_result
    dice_total:
      dice_total
    bonus:
      @bonus
    result:
      result
    type:
      @type

  @searchString: (string) ->
    result = string.match Dice.pattern
    return false unless result
    result[0]

module.exports = Dice