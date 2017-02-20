package dr;

using thx.Arrays;
using thx.Functions;
import dr.DiceExpression;

class Roller {
  var random: Int -> Int;
  public function new(random: Int -> Int) {
    this.random = random;
  }

  public function roll<T>(expr: DiceExpression<T>): DiceExpression<Int> {
    return switch expr {
      case Roll(roll):
        Roll(basicRoll(roll));
      case RollBag(dice, extractor, meta):
        var rolls = extractRolls(dice, extractor);
        var result = extractResult(rolls, extractor);
        RollBag(DiceSet(rolls), extractor, result);
      case RollExpressions(exprs, extractor, meta):
        var exaluatedExpressions = exprs.map(roll),
            result = extractExpressionResults(exaluatedExpressions, extractor);
        RollExpressions(exaluatedExpressions, extractor, result);
      case BinaryOp(op, a, b, meta):
        var ra = roll(a),
            rb = roll(b);
        switch op {
          case Sum:
            BinaryOp(Sum, ra, rb, DiceExpressionExtensions.extractMeta(ra) + DiceExpressionExtensions.extractMeta(rb));
          case Difference:
            BinaryOp(Difference, ra, rb, DiceExpressionExtensions.extractMeta(ra) - DiceExpressionExtensions.extractMeta(rb));
          case Division:
            BinaryOp(Difference, ra, rb, Std.int(DiceExpressionExtensions.extractMeta(ra) / DiceExpressionExtensions.extractMeta(rb)));
          case Multiplication:
            BinaryOp(Difference, ra, rb, DiceExpressionExtensions.extractMeta(ra) * DiceExpressionExtensions.extractMeta(rb));
        }
      case UnaryOp(Negate, a, meta):
        var ra = roll(a);
        UnaryOp(Negate, ra, -DiceExpressionExtensions.extractMeta(ra));
    };
  }

  function basicRoll<T>(roll: BasicRoll<T>): BasicRoll<Int> return switch roll {
    case One(die):
      One(die.roll(random));
    case Bag(list, meta):
      var rolls = list.map(basicRoll);
      var result = sumBasicRoll(rolls);
      Bag(rolls, result);
    case Repeat(times, die, meta):
      var rolls = [for(i in 0...times) die.roll(random)];
      var result = sumDice(rolls);
      Bag(rolls.map(One), result);
    case Literal(value, meta):
      Literal(value, value);
  }

  function extractRolls(dice, extractor)
    return switch extractor {
      case ExplodeOn(explodeOne):
        explodeRolls(diceBagToArrayOfDice(dice), explodeOne);
    };

  function sumDice<T>(rolls: Array<Die<Int>>)
    return rolls.reduce(function(acc, roll) return acc + roll.meta, 0);

  function sumBasicRoll<T>(rolls: Array<BasicRoll<Int>>)
    return rolls.reduce(function(acc, roll) return acc + switch roll {
      case One(die):
        die.meta;
      case Bag(_, meta) |
           Repeat(_, _, meta) |
           Literal(_, meta):
        meta;
    }, 0);

  function sumResults<T>(rolls: Array<DiceExpression<Int>>)
    return rolls.reduce(function(acc, roll) return acc + DiceExpressionExtensions.extractMeta(roll), 0);

  function extractResult<T>(rolls: Array<Die<Int>>, extractor: BagExtractor)
    return switch extractor {
      case ExplodeOn(explodeOn):
        rolls.reduce(function(acc, roll) return acc + roll.meta, 0);
    };

  function extractExpressionResults<T>(exprs: Array<DiceExpression<Int>>, extractor: ExpressionExtractor) {
    exprs = flattenExprs(exprs);
    return switch extractor {
      case Average:
        Std.int(exprs.reduce(function(acc, expr) return acc + DiceExpressionExtensions.extractMeta(expr), 0) / exprs.length);
      case Sum:
        exprs.reduce(function(acc, expr) return acc + DiceExpressionExtensions.extractMeta(expr), 0);
      case Min:
        exprs.map(DiceExpressionExtensions.extractMeta).min();
      case Max:
        exprs.map(DiceExpressionExtensions.extractMeta).max();
      case DropLow(drop):
        exprs.map(DiceExpressionExtensions.extractMeta).order(thx.Ints.compare).slice(drop).sum();
      case KeepHigh(keep):
        exprs.map(DiceExpressionExtensions.extractMeta).order(thx.Ints.compare).reversed().slice(0, keep).sum();
    };
  }

  function flattenExprs<T>(exprs: Array<DiceExpression<Int>>) {
    return if(exprs.length == 1) {
      switch exprs[0] {
        case Roll(Bag(rolls, _)):
          rolls.map.fn(Roll(_));
        case RollExpressions(exprs, _):
          exprs;
        case _:
          exprs;
      }
    } else {
      exprs;
    }
  }

  function diceBagToArrayOfDice<T>(group: DiceBag<T>): Array<Die<T>>
    return switch group {
      case DiceSet(dice):
        dice;
      case RepeatDie(times, die):
        [for(i in 0...times) die];
    };

  function explodeRolls<T>(dice: Array<Die<T>>, explodeOn: Int): Array<Die<Int>> {
    var rolls = dice.map.fn(_.roll(random));
    var explosives = rolls
          .filter.fn(_.meta >= explodeOn)
          .map.fn(new Die(_.sides, thx.Unit.unit));
    return rolls.concat(
      explosives.length == 0 ? [] :
      explodeRolls(explosives, explodeOn)
    );
  }
}
