package dapi;

import thx.Unit;
using thx.Arrays;
using thx.Functions;
import dapi.DiceResult;

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
      case RollAndExplode(dice, explodeOn, meta):
        var rolls = explodeRolls(random, dice, explodeOn);
        var result = rolls.reduce(function(acc, roll) return acc + roll.meta.result, 0);
        RollAndExplode(rolls, explodeOn, { result: result, meta: meta});
      case BinaryOp(op, a, b, meta):
        var ra = roll(a),
            rb = roll(b);
        switch op {
          case Sum:
            BinaryOp(Sum, ra, rb, {
              result: DiceResults.extractResult(ra) + DiceResults.extractResult(rb),
              meta: meta
            });
          case Difference:
            BinaryOp(Difference, ra, rb, {
              result: DiceResults.extractResult(ra) + DiceResults.extractResult(rb),
              meta: meta
            });
        }
      case _: null;
    };
  }

  static function explodeRolls<T>(random: Int -> Int, dice: Array<Die<T>>, explodeOn: Int): Array<Die<DiceResultMeta<T>>> {
    var rolls = dice.map.fn(_.roll(random));
    var explosives = rolls
          .filter.fn(_.meta.result >= explodeOn)
          .map.fn(new Die(_.sides, _.meta.meta));
    return rolls.concat(
      explosives.length == 0 ? [] :
      explodeRolls(random, explosives, explodeOn)
    );
  }

  public function rollDice(dice: Int, sides: Int): DiceResult<Unit>
    return roll(RollMany([for(i in 0...dice) Die.withSides(sides)], unit));

  public function rollOne(sides: Int): DiceResult<Unit>
    return roll(RollOne(Die.withSides(sides)));

  public function rollDiceAndDropLow(dice: Int, sides: Int, drop: Int): DiceResult<Unit>
    return roll(RollAndDropLow([for(i in 0...dice) Die.withSides(sides)], drop, unit));

  public function rollDiceAndKeepHigh(dice: Int, sides: Int, keep: Int): DiceResult<Unit>
    return roll(RollAndKeepHigh([for(i in 0...dice) Die.withSides(sides)], keep, unit));

  public function rollDiceAndExplode(dice: Int, sides: Int, explodeOn: Int): DiceResult<Unit>
    return roll(RollAndExplode([for(i in 0...dice) Die.withSides(sides)], explodeOn, unit));
}
