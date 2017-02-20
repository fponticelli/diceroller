package dr;

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
      case Roll(roll):
        Roll(basicRoll(roll));
      case RollBag(dice, extractor, meta):
        var rolls = extractRolls(dice, extractor);
        var result = extractResult(rolls, extractor);
        RollBag(DiceSet(rolls), extractor, { result: result, meta: meta});
      case RollExpressions(exprs, extractor, meta):
        var exaluatedExpressions = exprs.map(roll),
            result = extractExpressionResults(exaluatedExpressions, extractor);
        RollExpressions(exaluatedExpressions, extractor, { result: result, meta: meta});
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
              result: DiceResults.extractResult(ra) - DiceResults.extractResult(rb),
              meta: meta
            });
          case Division:
            BinaryOp(Difference, ra, rb, {
              result: Std.int(DiceResults.extractResult(ra) / DiceResults.extractResult(rb)),
              meta: meta
            });
          case Multiplication:
            BinaryOp(Difference, ra, rb, {
              result: DiceResults.extractResult(ra) * DiceResults.extractResult(rb),
              meta: meta
            });
        }
      case UnaryOp(Negate, a, meta):
        var ra = roll(a);
        UnaryOp(Negate, ra, {
          result: -DiceResults.extractResult(ra),
          meta: meta
        });
    };
  }

  function basicRoll<T>(roll: BasicRoll<T>): BasicRoll<DiceResultMeta<T>> return switch roll {
    case One(die):
      One(die.roll(random));
    case Bag(list, meta):
      var rolls = list.map(basicRoll);
      var result = sumBasicRoll(rolls);
      Bag(rolls, {result: result, meta: meta});
    case Repeat(times, die, meta):
      var rolls = [for(i in 0...times) die.roll(random)];
      var result = sumDice(rolls);
      Bag(rolls.map(One), {result: result, meta: meta});
    case Literal(value, meta):
      Literal(value, {result: value, meta: meta});
  }

  function extractRolls(dice, extractor)
    return switch extractor {
      case ExplodeOn(explodeOne):
        explodeRolls(diceBagToArrayOfDice(dice), explodeOne);
    };

  function sumDice<T>(rolls: Array<Die<DiceResultMeta<T>>>)
    return rolls.reduce(function(acc, roll) return acc + roll.meta.result, 0);

  function sumBasicRoll<T>(rolls: Array<BasicRoll<DiceResultMeta<T>>>)
    return rolls.reduce(function(acc, roll) return acc + switch roll {
      case One(die):
        die.meta.result;
      case Bag(_, meta) |
           Repeat(_, _, meta) |
           Literal(_, meta):
        meta.result;
    }, 0);

  function sumResults<T>(rolls: Array<DiceResult<T>>)
    return rolls.reduce(function(acc, roll) return acc + DiceResults.extractResult(roll), 0);

  function extractResult<T>(rolls: Array<Die<DiceResultMeta<T>>>, extractor: BagExtractor)
    return switch extractor {
      case ExplodeOn(explodeOn):
        rolls.reduce(function(acc, roll) return acc + roll.meta.result, 0);
    };

  function extractExpressionResults<T>(exprs: Array<DiceResult<T>>, extractor: ExpressionExtractor)
    return switch extractor {
      case Average:
        Std.int(exprs.reduce(function(acc, expr) return acc + DiceResults.extractResult(expr), 0) / exprs.length);
      case Sum:
        exprs.reduce(function(acc, expr) return acc + DiceResults.extractResult(expr), 0);
      case DropLow(drop):
        exprs.map(DiceResults.extractResult).order(thx.Ints.compare).slice(drop).sum();
      case KeepHigh(keep):
        exprs.map(DiceResults.extractResult).order(thx.Ints.compare).reversed().slice(0, keep).sum();
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
}
