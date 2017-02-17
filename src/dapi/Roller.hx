package dapi;

import thx.Unit;
using thx.Arrays;
using thx.Functions;

class Roller {
  var random: Int -> Int;
  public function new(random: Int -> Int) {
    this.random = random;
  }

  public function roll<T>(expr: DiceExpression<T>): DiceResult<T> {
    return switch expr {
      case RollOne(die):
        RollOne(die.roll(random));
      case RollMany(dice, meta):
        var rolls = dice.map.fn(_.roll(random));
        var result = rolls.reduce(function(acc, roll) return acc + roll.meta.result, 0);
        RollMany(rolls, { result: result, meta: meta});
      case RollAndDropLow(dice, drop, meta):
        var rolls = dice.map.fn(_.roll(random));
        var result = rolls.map.fn(_.meta.result).order(thx.Ints.compare).slice(drop).sum();
        RollAndDropLow(rolls, drop, { result: result, meta: meta});
      case RollAndKeepHigh(dice, keep, meta):
        var rolls = dice.map.fn(_.roll(random));
        var result = rolls.map.fn(_.meta.result).order(thx.Ints.compare).reversed().slice(0, keep).sum();
        RollAndKeepHigh(rolls, keep, { result: result, meta: meta});
      // case RollAndExplode(dice, explodeOn):
      // case BinaryOp(op, a, b, meta):
      case _: null;
    };
  }

  public function rollDice(dice: Int, sides: Int): DiceResult<Unit> {
    return roll(RollMany([for(i in 0...dice) Die.withSides(sides)], unit));
  }
}
