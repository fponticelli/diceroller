package dapi;

import thx.Unit;
using thx.Arrays;
using thx.Functions;
import dapi.DiceExpression;
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
        var rolls = groupToDice(dice).map.fn(_.roll(random));
        var result = rolls.reduce(function(acc, roll) return acc + roll.meta.result, 0);
        RollMany(DiceList(rolls), { result: result, meta: meta});
      case RollAndDropLow(dice, drop, meta):
        var rolls = groupToDice(dice).map.fn(_.roll(random));
        var result = rolls.map.fn(_.meta.result).order(thx.Ints.compare).slice(drop).sum();
        RollAndDropLow(DiceList(rolls), drop, { result: result, meta: meta});
      case RollAndKeepHigh(dice, keep, meta):
        var rolls = groupToDice(dice).map.fn(_.roll(random));
        var result = rolls.map.fn(_.meta.result).order(thx.Ints.compare).reversed().slice(0, keep).sum();
        RollAndKeepHigh(DiceList(rolls), keep, { result: result, meta: meta});
      case RollAndExplode(dice, explodeOn, meta):
        var rolls = explodeRolls(random, groupToDice(dice), explodeOn);
        var result = rolls.reduce(function(acc, roll) return acc + roll.meta.result, 0);
        RollAndExplode(DiceList(rolls), explodeOn, { result: result, meta: meta});
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

  static function groupToDice<T>(group: DiceGroup<T>): Array<Die<T>>
    return switch group {
      case DiceList(dice):
         dice;
      case RepeatDie(times, die):
        [for(i in 0...times) die];
    };

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
    return roll(RollMany(RepeatDie(dice, new Die(sides, unit)), unit));

  public function rollOne(sides: Int): DiceResult<Unit>
    return roll(RollOne(Die.withSides(sides)));

  public function rollDiceAndDropLow(dice: Int, sides: Int, drop: Int): DiceResult<Unit>
    return roll(RollAndDropLow(RepeatDie(dice, new Die(sides, unit)), drop, unit));

  public function rollDiceAndKeepHigh(dice: Int, sides: Int, keep: Int): DiceResult<Unit>
    return roll(RollAndKeepHigh(RepeatDie(dice, new Die(sides, unit)), keep, unit));

  public function rollDiceAndExplode(dice: Int, sides: Int, explodeOn: Int): DiceResult<Unit>
    return roll(RollAndExplode(RepeatDie(dice, new Die(sides, unit)), explodeOn, unit));
}
