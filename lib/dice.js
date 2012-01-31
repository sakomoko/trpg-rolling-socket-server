var Dice;

Dice = (function() {

  Dice.pattern = /\d{1,3}d\d{1,3}((\+|\-)\d+)?(\*\d+)?$/im;

  function Dice(diceString) {
    var i, result, _ref, _ref2, _ref3;
    this.diceString = diceString;
    result = this.diceString.match(/^(\d+)d(\d+)?((\+|\-)(\d)+)?(\*(\d+))?/i);
    this.num = result[1] - 0;
    this.type = result[2] - 0;
    this.bonus = ((_ref = result[3]) != null ? _ref : 0) - 0;
    this.rollCount = ((_ref2 = result[7]) != null ? _ref2 : 1) - 0;
    this.result = this.rollCount > 1 ? new Array : 0;
    this.rollResult = [];
    for (i = 1, _ref3 = this.rollCount; 1 <= _ref3 ? i <= _ref3 : i >= _ref3; 1 <= _ref3 ? i++ : i--) {
      this.rollResult.push(this.roll());
    }
  }

  Dice.prototype.roll = function() {
    var dice_result, dice_total, i, result, value, _i, _len;
    dice_result = (function() {
      var _ref, _results;
      _results = [];
      for (i = 1, _ref = this.num; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
        _results.push(Math.floor(Math.random() * this.type) + 1);
      }
      return _results;
    }).call(this);
    dice_total = 0;
    for (_i = 0, _len = dice_result.length; _i < _len; _i++) {
      value = dice_result[_i];
      dice_total += value;
    }
    result = dice_total + this.bonus;
    if (this.result instanceof Array) {
      this.result.push(result);
    } else {
      this.result = result;
    }
    return {
      dice_result: dice_result,
      dice_total: dice_total,
      bonus: this.bonus,
      result: result,
      type: this.type
    };
  };

  Dice.searchString = function(string) {
    var result;
    result = string.match(Dice.pattern);
    if (!result) return false;
    return result[0];
  };

  Dice.removeString = function(string) {
    var result;
    result = string.replace(Dice.pattern, '');
    if (!result) return string;
    return result;
  };

  return Dice;

})();

module.exports = Dice;
