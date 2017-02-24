package dr;

using thx.Arrays;
using thx.Functions;
import dr.Algebra;
import dr.DiceExpression;
import dr.RollResult;
import dr.RollResultExtensions.getResult;

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
      case Die(sides):
        OneResult({ result: algebra.die(sides), sides: sides });
      case Dice(times, sides):
        var rolls = [for(i in 0...times) { result: algebra.die(sides), sides: sides }];
        var result = sumDice(rolls);
        DiceReducerResult(
          rolls.map(OneResult),
          Sum,
          result);
      case Literal(value):
        LiteralResult(value, algebra.ofLiteral(value));
      case DiceMap(dice, functor):
        var rolls = extractRolls(dice, functor);
        var result = extractResult(rolls, functor);
        DiceMapResult(rolls.map.fn(OneResult(_)), functor, result);
      case DiceReducer(exprs, aggregator):
        var exaluatedExpressions = exprs.map(roll),
            result = extractExpressionResults(exaluatedExpressions, aggregator);
        DiceReducerResult(exaluatedExpressions, aggregator, result);
      case BinaryOp(op, a, b):
        var ra = roll(a),
            rb = roll(b);
        switch op {
          case Sum:
            BinaryOpResult(Sum, ra, rb, algebra.sum(getResult(ra), getResult(rb)));
          case Difference:
            BinaryOpResult(Difference, ra, rb, algebra.subtract(getResult(ra), getResult(rb)));
          case Division:
            BinaryOpResult(Division, ra, rb, algebra.divide(getResult(ra), getResult(rb)));
          case Multiplication:
            BinaryOpResult(Multiplication, ra, rb, algebra.multiply(getResult(ra), getResult(rb)));
        }
      case UnaryOp(Negate, a):
        var ra = roll(a);
        UnaryOpResult(Negate, ra, algebra.negate(getResult(ra)));
    };
  }

  function extractRolls(dice, functor): Array<DieResult<Result>>
    return (switch functor {
      case Explode(times, range):
        explodeRolls(dice, times, range);
      case Reroll(times, range):
        rerollRolls(dice, times, range);
    });

  function sumDice(rolls: Array<DieResult<Result>>)
    return rolls.reduce(function(acc, roll) return algebra.sum(acc, roll.result), algebra.zero);

  function sumResults(rolls: Array<RollResult<Result>>)
    return rolls.map(getResult).reduce(algebra.sum, algebra.zero);

  function extractResult(rolls: Array<DieResult<Result>>, functor: DiceFunctor)
    return switch functor {
      case Explode(times, range) | Reroll(times, range):
        // TODO needs work?
        rolls.map.fn(_.result).reduce(algebra.sum, algebra.zero);
    };

  function extractExpressionResults(exprs: Array<RollResult<Result>>, aggregator: DiceReduce) {
    exprs = flattenExprs(exprs);
    return switch aggregator {
      case Average:
        algebra.average(exprs.map(getResult));
      case Sum:
        exprs.map(getResult).reduce(algebra.sum, algebra.zero);
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
        case DiceReducerResult(exprs, _):
          exprs;
        case _:
          exprs;
      }
    } else {
      exprs;
    }
  }

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
    return switch times {
      case Always:
        rerollRollsTimes(dice, 1000, range); // TODO 1000 could be calculated a little better
      case UpTo(value):
        rerollRollsTimes(dice, value, range);
    };
  }

  function rerollRollsTimes(dice: Array<Sides>, times: Int, range: Range): Array<DieResult<Result>> {
    var rolls: Array<DieResult<Result>> = dice.map.fn({ result: algebra.die(_), sides: _ });
    if(times == 0 || rolls.length == 0)
      return rolls;

    var rerolls = rolls.filter.fn(compareToRange(_.result, range));
    var keeprolls = rolls.filter.fn(!compareToRange(_.result, range));
    return keeprolls.concat(rerollRollsTimes(rerolls.map.fn(_.sides), times-1, range));
  }
}
