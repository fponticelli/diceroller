package dr;

using thx.Arrays;
using thx.Functions;
import dr.DiceExpression;
using dr.DiceExpressionExtensions;
import dr.DiceExpressionExtensions.getMeta;
import dr.Algebra;

class Roller<Meta> {
  public static function int(roll: Sides -> Int)
    return new Roller(new IntAlgebra(roll));
  public static function discrete()
    return new Roller(new DiscreteAlgebra());

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
    return (switch extractor {
      case Explode(times, range):
        explodeRolls(diceBagToArrayOfDice(dice), times, range);
      case Reroll(times, range):
        rerollRolls(diceBagToArrayOfDice(dice), times, range);
    });

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
    return rolls.map.fn(_.getMeta()).reduce(algebra.sum, algebra.zero);

  function extractResult<T>(rolls: Array<Die<Meta>>, extractor: BagExtractor)
    return switch extractor {
      case Explode(times, range):
        // TODO needs work?
        rolls.map.fn(_.meta).reduce(algebra.sum, algebra.zero);
      case Reroll(times, range):
        // TODO needs work?
        rolls.map.fn(_.meta).reduce(algebra.sum, algebra.zero);
    };

  function extractExpressionResults<T>(exprs: Array<DiceExpression<Meta>>, extractor: ExpressionExtractor) {
    exprs = flattenExprs(exprs);
    return switch extractor {
      case Average:
        algebra.average(exprs.map(getMeta));
      case Sum:
        exprs.map.fn(_.getMeta()).reduce(algebra.sum, algebra.zero);
      case Min:
        exprs.map(getMeta).order(algebra.compare).shift();
      case Max:
        exprs.map(getMeta).order(algebra.compare).pop();
      case Drop(dir, value):
        switch dir {
          case Low:
            exprs.map(getMeta).order(algebra.compare).slice(value).reduce(algebra.sum, algebra.zero);
          case High:
            exprs.map(getMeta).order(algebra.compare).slice(0, -value).reduce(algebra.sum, algebra.zero);
        };
      case Keep(dir, value):
        switch dir {
          case Low:
            exprs.map(getMeta).order(algebra.compare).slice(0,value).reduce(algebra.sum, algebra.zero);
          case High:
            exprs.map(getMeta).order(algebra.compare).slice(-value).reduce(algebra.sum, algebra.zero);
        };
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

  function explodeRolls<T>(dice: Array<Die<T>>, times: Times, range: Range): Array<Die<Meta>> {
    return switch times {
      case Always:
        explodeRollsTimes(dice, 1000, range); // TODO 1000 could be calculated a little better
      case UpTo(value):
        explodeRollsTimes(dice, value, range);
    };
  }

  function explodeRollsTimes<T>(dice: Array<Die<T>>, times: Int, range: Range): Array<Die<Meta>> {
    var rolls: Array<Die<Meta>> = dice.map.fn(_.roll(algebra.die));
    if(times == 0 || rolls.length == 0)
      return rolls;

    var explosives = rolls
          .filter.fn(compareToRange(_.meta, range))
          .map.fn(new Die(_.sides, thx.Unit.unit));
    return rolls.concat(explodeRollsTimes(explosives, times-1, range));
  }

  function compareToRange(v: Meta, range: Range): Bool {
    return switch range {
      case Exact(value):
        algebra.compareToSides(v, value) == 0;
      case Between(minInclusive, maxInclusive):
        algebra.compareToSides(v, minInclusive) >= 0 && algebra.compareToSides(v, maxInclusive) <= 0;
      case ValueOrMore(value):
        algebra.compareToSides(v, value) >= 0;
      case ValueOrLess(value):
        algebra.compareToSides(v, value) <= 0;
      case Composite(ranges):
        ranges.reduce(function(acc, range) {
          return acc ||  compareToRange(v, range);
        }, false);
    };
  }

  function rerollRolls<T>(dice: Array<Die<T>>, times: Times, range: Range): Array<Die<Meta>> {
    var rolls = dice.map.fn(_.roll(algebra.die));
    var rerolls = [];
    // TODO
    // rolls
    //       .filter.fn(algebra.compareToSides(_.meta, explodeOn) >= 0)
    //       .map.fn(new Die(_.sides, thx.Unit.unit));
    return rolls.concat(
      rerolls.length == 0 ? [] :
      rerollRolls(rerolls, times, range)
    );
  }
}
