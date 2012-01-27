var Dice;

Dice = (function() {

  function Dice(diceString) {
    var result, _ref, _ref2;
    this.diceString = diceString;
    result = this.diceString.match(/^(\d+)d(\d+)?((\+|\-)(\d)+)?(\*(\d))?/i);
    this.num = result[1] - 0;
    this.type = result[2] - 0;
    this.bonus = ((_ref = result[3]) != null ? _ref : 0) - 0;
    this.rollCount = ((_ref2 = result[7]) != null ? _ref2 : 1) - 0;
    this.rollResult = [];
    this.rollResult.push(this.roll());
  }

  Dice.prototype.roll = function() {
    var i, result, total, value, _i, _len;
    result = (function() {
      var _ref, _results;
      _results = [];
      for (i = 1, _ref = this.num; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
        _results.push(Math.floor(Math.random() * this.type) + 1);
      }
      return _results;
    }).call(this);
    total = 0;
    for (_i = 0, _len = result.length; _i < _len; _i++) {
      value = result[_i];
      total += value;
    }
    this.result = total + this.bonus;
    return {
      dice_result: result,
      dice_total: total,
      bonus: this.bonus,
      result: this.result
    };
  };

  return Dice;

})();

module.exports = Dice;
