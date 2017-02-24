package dr;

using thx.Arrays;
using thx.Functions;
import dr.DiceExpression;
import dr.RollResult;
using dr.DiceExpressionExtensions;
import dr.DiceExpressionExtensions.DiceResultExtensions.getResult;
import dr.Algebra;

class Roller<Result> {
  public static function int(roll: Sides -> Int)
    return new Roller(new IntAlgebra(roll));
  public static function discrete()
    return new Roller(new DiscreteAlgebra());

  var algebra: Algebra<Result>;
  public function new(algebra: Algebra<Result>) {
    this.algebra = algebra;
  }

  public function roll(expr: DiceExpression): RollResult<Result> {
    return switch expr {
      case One(sides):
        One({ result: algebra.die(sides), sides: sides });
      case Repeat(times, sides):
        var rolls = [for(i in 0...times) { result: algebra.die(sides), sides: sides }];
        var result = sumDice(rolls);
        RollExpressions(
          rolls.map(One),
          Sum,
          result);
      case Literal(value):
        Literal(value, algebra.ofLiteral(value));
      case RollBag(dice, extractor):
        var rolls = extractRolls(dice, extractor);
        var result = extractResult(rolls, extractor);
        RollResult.RollBag(rolls.map.fn(RollResult.One(_)), extractor, result);
      case RollExpressions(exprs, extractor):
        var exaluatedExpressions = exprs.map(roll),
            result = extractExpressionResults(exaluatedExpressions, extractor);
        RollExpressions(exaluatedExpressions, extractor, result);
      case BinaryOp(op, a, b):
        var ra = roll(a),
            rb = roll(b);
        switch op {
          case Sum:
            BinaryOp(Sum, ra, rb, algebra.sum(ra.getResult(), rb.getResult()));
          case Difference:
            BinaryOp(Difference, ra, rb, algebra.subtract(ra.getResult(), rb.getResult()));
          case Division:
            BinaryOp(Division, ra, rb, algebra.divide(ra.getResult(), rb.getResult()));
          case Multiplication:
            BinaryOp(Multiplication, ra, rb, algebra.multiply(ra.getResult(), rb.getResult()));
        }
      case UnaryOp(Negate, a):
        var ra = roll(a);
        UnaryOp(Negate, ra, algebra.negate(ra.getResult()));
    };
  }

  function extractRolls(dice, extractor): Array<DieResult<Result>>
    return (switch extractor {
      case Explode(times, range):
        explodeRolls(diceBagToArrayOfDice(dice), times, range);
      case Reroll(times, range):
        rerollRolls(diceBagToArrayOfDice(dice), times, range);
    });

  function sumDice(rolls: Array<DieResult<Result>>)
    return rolls.reduce(function(acc, roll) return algebra.sum(acc, roll.result), algebra.zero);

  function sumResults(rolls: Array<RollResult<Result>>)
    return rolls.map.fn(_.getResult()).reduce(algebra.sum, algebra.zero);

  function extractResult(rolls: Array<DieResult<Result>>, extractor: BagExtractor)
    return switch extractor {
      case Explode(times, range) | Reroll(times, range):
        // TODO needs work?
        rolls.map.fn(_.result).reduce(algebra.sum, algebra.zero);
    };

  function extractExpressionResults(exprs: Array<RollResult<Result>>, extractor: ExpressionExtractor) {
    exprs = flattenExprs(exprs);
    return switch extractor {
      case Average:
        algebra.average(exprs.map(getResult));
      case Sum:
        exprs.map.fn(_.getResult()).reduce(algebra.sum, algebra.zero);
      case Min:
        exprs.map(getResult).order(algebra.compare).shift();
      case Max:
        exprs.map(getResult).order(algebra.compare).pop();
      case Drop(dir, value):
        switch dir {
          case Low:
            exprs.map(getResult).order(algebra.compare).slice(value).reduce(algebra.sum, algebra.zero);
          case High:
            exprs.map(getResult).order(algebra.compare).slice(0, -value).reduce(algebra.sum, algebra.zero);
        };
      case Keep(dir, value):
        switch dir {
          case Low:
            exprs.map(getResult).order(algebra.compare).slice(0,value).reduce(algebra.sum, algebra.zero);
          case High:
            exprs.map(getResult).order(algebra.compare).slice(-value).reduce(algebra.sum, algebra.zero);
        };
    };
  }

  function flattenExprs(exprs: Array<RollResult<Result>>): Array<RollResult<Result>> {
    return if(exprs.length == 1) {
      switch exprs[0] {
        case RollExpressions(exprs, _):
          exprs;
        case _:
          exprs;
      }
    } else {
      exprs;
    }
  }

  function diceBagToArrayOfDice(group: DiceBag): Array<Sides>
    return switch group {
      case DiceSet(dice):
        dice;
      case RepeatDie(times, sides):
        [for(i in 0...times) sides];
    };

  function explodeRolls(dice: Array<Sides>, times: Times, range: Range): Array<DieResult<Result>> {
    return switch times {
      case Always:
        explodeRollsTimes(dice, 1000, range); // TODO 1000 could be calculated a little better
      case UpTo(value):
        explodeRollsTimes(dice, value, range);
    };
  }

  function explodeRollsTimes(dice: Array<Sides>, times: Int, range: Range): Array<DieResult<Result>> {
    var rolls: Array<DieResult<Result>> = dice.map.fn({ result: algebra.die(_), sides: _ });
    if(times == 0 || rolls.length == 0)
      return rolls;

    var explosives = rolls
          .filter.fn(compareToRange(_.result, range));
    return rolls.concat(explodeRollsTimes(explosives.map.fn(_.sides), times-1, range));
  }

  function compareToRange(v: Result, range: Range): Bool {
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

  function rerollRolls(dice: Array<Sides>, times: Times, range: Range): Array<DieResult<Result>> {
    var rolls = dice.map.fn({ result: algebra.die(_), sides: _ });
    var rerolls = [];
    // TODO
    // rolls
    //       .filter.fn(algebra.compareToSides(_.result, explodeOn) >= 0)
    //       .map.fn(new Die(_.sides, thx.Unit.unit));
    return rolls.concat(
      rerolls.length == 0 ? [] :
      rerollRolls(rerolls, times, range)
    );
  }
}
