package dr;

import thx.Unit;
using thx.Arrays;
using thx.Functions;
import dr.DiceExpression;
import dr.DiceResult;

class Roller {
  var random: Int -> Int;
  public function new(random: Int -> Int) {
    this.random = random;
  }

  public function roll<T>(expr: DiceExpression<T>): DiceResult<T> {
    return switch expr {
      case Roll(One(die)):
        Roll(One(die.roll(random)));
      case Roll(Repeat(rolls, die, meta)):
        var rolls = [for(i in 0...rolls) die].map.fn(_.roll(random));
        var result = sumResults(rolls);
        Roll(Bag(rolls, { result: result, meta: meta }));
      case Roll(Bag(list, meta)):
        var rolls = list.map.fn(_.roll(random));
        var result = sumResults(rolls);
        Roll(Bag(rolls, { result: result, meta: meta }));
      case Roll(Literal(value, meta)):
        Roll(Literal(value, { result: value, meta: meta }));
      case RollBag(dice, extractor, meta):
        var rolls = extractRolls(dice, extractor);
        var result = extractResult(rolls, extractor);
        RollBag(DiceSet(rolls), extractor, { result: result, meta: meta});
      case RollExpressions(exprs, extractor, meta):
        var exaluatedExpressions = expressionBagToArrayOfExpression(exprs).map(roll),
            result = extractExpressionResults(exaluatedExpressions, extractor);
        RollExpressions(ExpressionSet(exaluatedExpressions), extractor, { result: result, meta: meta});
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
    };
  }

  function extractRolls(dice, extractor)
    return switch extractor {
      case Sum | DropLow(_) | KeepHigh(_):
        diceBagToArrayOfDice(dice).map.fn(_.roll(random));
      case ExplodeOn(explodeOne):
        explodeRolls(diceBagToArrayOfDice(dice), explodeOne);
    };

  function sumResults<T>(rolls: Array<Die<DiceResultMeta<T>>>)
    return rolls.reduce(function(acc, roll) return acc + roll.meta.result, 0);

  function extractResult<T>(rolls: Array<Die<DiceResultMeta<T>>>, extractor: BagExtractor)
    return switch extractor {
      case Sum:
        rolls.reduce(function(acc, roll) return acc + roll.meta.result, 0);
      case DropLow(drop):
        rolls.map.fn(_.meta.result).order(thx.Ints.compare).slice(drop).sum();
      case KeepHigh(keep):
        rolls.map.fn(_.meta.result).order(thx.Ints.compare).reversed().slice(0, keep).sum();
      case ExplodeOn(explodeOn):
        rolls.reduce(function(acc, roll) return acc + roll.meta.result, 0);
    };

  function extractExpressionResults<T>(exprs: Array<DiceResult<T>>, extractor: ExpressionExtractor)
    return switch extractor {
      case Sum:
        exprs.reduce(function(acc, expr) return acc + DiceResults.extractResult(expr), 0);
      case DropLow(drop):
        exprs.map(DiceResults.extractResult).order(thx.Ints.compare).slice(drop).sum();
      case KeepHigh(keep):
        exprs.map(DiceResults.extractResult).order(thx.Ints.compare).reversed().slice(0, keep).sum();
    };

  function expressionBagToArrayOfExpression<T>(exprs: ExpressionBag<T>): Array<DiceExpression<T>>
    return switch exprs {
      case ExpressionSet(exprs):
        exprs;
      case RepeatDie(times, die):
        [for(i in 0...times) Roll(One(die))];
    };

  function diceBagToArrayOfDice<T>(group: DiceBag<T>): Array<Die<T>>
    return switch group {
      case DiceSet(dice):
        dice;
      case RepeatDie(times, die):
        [for(i in 0...times) die];
    };

  function explodeRolls<T>(dice: Array<Die<T>>, explodeOn: Int): Array<Die<DiceResultMeta<T>>> {
    var rolls = dice.map.fn(_.roll(random));
    var explosives = rolls
          .filter.fn(_.meta.result >= explodeOn)
          .map.fn(new Die(_.sides, _.meta.meta));
    return rolls.concat(
      explosives.length == 0 ? [] :
      explodeRolls(explosives, explodeOn)
    );
  }

  public function rollDice(dice: Int, sides: Int): DiceResult<Unit>
    return roll(RollBag(RepeatDie(dice, new Die(sides, unit)), Sum, unit));

  public function rollOne(sides: Int): DiceResult<Unit>
    return roll(Roll(One(Die.withSides(sides))));

  public function rollDiceAndDropLow(dice: Int, sides: Int, drop: Int): DiceResult<Unit>
    return roll(RollBag(RepeatDie(dice, new Die(sides, unit)), DropLow(drop), unit));

  public function rollDiceAndKeepHigh(dice: Int, sides: Int, keep: Int): DiceResult<Unit>
    return roll(RollBag(RepeatDie(dice, new Die(sides, unit)), KeepHigh(keep), unit));

  public function rollDiceAndExplode(dice: Int, sides: Int, explodeOn: Int): DiceResult<Unit>
    return roll(RollBag(RepeatDie(dice, new Die(sides, unit)), ExplodeOn(explodeOn), unit));
}