package dr;

using thx.Arrays;
using thx.Functions;
import dr.DiceExpression;
using dr.DiceExpressionExtensions;
import dr.DiceExpressionExtensions.getMeta;
import dr.Algebra;

class Roller<Meta> {
  public static function intRoller(roll: Sides -> Int)
    return new Roller(new IntAlgebra(roll));

  var algebra: Algebra<Meta>;
  public function new(algebra: Algebra<Meta>) {
    this.algebra = algebra;
  }

  public function roll<T>(expr: DiceExpression<T>): DiceExpression<Meta> {
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
            BinaryOp(Sum, ra, rb, algebra.sum(ra.getMeta(), rb.getMeta()));
          case Difference:
            BinaryOp(Difference, ra, rb, algebra.subtract(ra.getMeta(), rb.getMeta()));
          case Division:
            BinaryOp(Difference, ra, rb, algebra.divide(ra.getMeta(), rb.getMeta()));
          case Multiplication:
            BinaryOp(Difference, ra, rb, algebra.multiply(ra.getMeta(), rb.getMeta()));
        }
      case UnaryOp(Negate, a, _):
        var ra = roll(a);
        UnaryOp(Negate, ra, algebra.negate(ra.getMeta()));
    };
  }

  function basicRoll<T>(roll: BasicRoll<T>): BasicRoll<Meta> return switch roll {
    case One(die):
      One(die.roll(algebra.die));
    case Bag(list, _):
      var rolls = list.map(basicRoll);
      var result = sumBasicRoll(rolls);
      Bag(rolls, result);
    case Repeat(times, die, _):
      var rolls = [for(i in 0...times) die.roll(algebra.die)];
      var result = sumDice(rolls);
      Bag(rolls.map(One), result);
    case Literal(value, _):
      Literal(value, algebra.ofLiteral(value));
  }

  function extractRolls(dice, extractor)
    return switch extractor {
      case ExplodeOn(explodeOne):
        explodeRolls(diceBagToArrayOfDice(dice), explodeOne);
    };

  function sumDice<T>(rolls: Array<Die<Meta>>)
    return rolls.reduce(function(acc, roll) return algebra.sum(acc, roll.meta), algebra.zero);

  function sumBasicRoll<T>(rolls: Array<BasicRoll<Meta>>)
    return rolls.reduce(function(acc, roll) return algebra.sum(acc, switch roll {
      case One(die):
        die.meta;
      case Bag(_, meta) |
           Repeat(_, _, meta) |
           Literal(_, meta):
        meta;
    }), algebra.zero);

  function sumResults<T>(rolls: Array<DiceExpression<Meta>>)
    return rolls.reduce(function(acc, roll) return algebra.sum(acc, roll.getMeta()), algebra.zero);

  function extractResult<T>(rolls: Array<Die<Meta>>, extractor: BagExtractor)
    return switch extractor {
      case ExplodeOn(explodeOn):
        rolls.reduce(function(acc, roll) return algebra.sum(acc, roll.meta), algebra.zero);
    };

  function extractExpressionResults<T>(exprs: Array<DiceExpression<Meta>>, extractor: ExpressionExtractor) {
    exprs = flattenExprs(exprs);
    return switch extractor {
      case Average:
        algebra.average(exprs.map(getMeta));
      case Sum:
        exprs.reduce(function(acc, expr) return algebra.sum(acc, expr.getMeta()), algebra.zero);
      case Min:
        exprs.map(getMeta).order(algebra.compare).shift();
      case Max:
        exprs.map(getMeta).order(algebra.compare).pop();
      case DropLow(drop):
        exprs.map(getMeta).filter(function(meta) {
          return algebra.compareToSides(meta, drop) >= 0;
        }).reduce(function(acc, meta) {
          return algebra.sum(acc, meta);
        }, algebra.zero);
      case KeepHigh(keep):
        exprs.map(getMeta).filter(function(meta) {
          return algebra.compareToSides(meta, keep) <= 0;
        }).reduce(function(acc, meta) {
          return algebra.sum(acc, meta);
        }, algebra.zero);
    };
  }

  function flattenExprs<T>(exprs: Array<DiceExpression<Meta>>) {
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

  function explodeRolls<T>(dice: Array<Die<T>>, explodeOn: Sides): Array<Die<Meta>> {
    var rolls = dice.map.fn(_.roll(algebra.die));
    var explosives = rolls
          .filter.fn(algebra.compareToSides(_.meta, explodeOn) >= 0)
          .map.fn(new Die(_.sides, thx.Unit.unit));
    return rolls.concat(
      explosives.length == 0 ? [] :
      explodeRolls(explosives, explodeOn)
    );
  }
}
