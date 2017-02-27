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
      case Literal(value):
        LiteralResult(value, algebra.ofLiteral(value));
      case DiceReduce(DiceExpressions(exprs), reducer):
        var rolls = exprs.map(roll),
            result = reduceRolls(rolls, reducer);
        DiceReduceResult(DiceExpressionsResult(rolls), reducer, result);
      case DiceReduce(DiceListWithFilter(DiceArray(dice), filter), reducer):
        var rolls = dice.map.fn(roll(Die(_))),
            filteredRolls = filterRolls(rolls, filter),
            keepFilteredRolls = keepFilteredRolls(filteredRolls),
            result = reduceRolls(keepFilteredRolls, reducer);
        DiceReduceResult(DiceFilterableResult(filteredRolls, filter), reducer, result);
      case DiceReduce(DiceListWithFilter(DiceExpressions(exprs), filter), reducer):
        var rolls = exprs.map(roll),
            filteredRolls = filterRolls(rolls, filter),
            keepFilteredRolls = keepFilteredRolls(filteredRolls),
            result = reduceRolls(keepFilteredRolls, reducer);
        DiceReduceResult(DiceFilterableResult(filteredRolls, filter), reducer, result);
      case DiceReduce(DiceListWithMap(dice, functor), reducer):
        var rolls = dice.map.fn({ result: algebra.die(_), sides: _ }),
            mapped = mapRolls(rolls, functor),
            keepMappedRolls = keepMappedRolls(mapped),
            result = reduceRolls(keepMappedRolls.map(OneResult), reducer);
        DiceReduceResult(DiceMapeableResult(mapped, functor), reducer, result);
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

  function mapRolls(rolls: Array<DieResult<Result>>, functor: DiceFunctor): Array<DiceResultMapped<Result>> {
    return switch functor {
      case Explode(Always, range): rolls.map(explodeRoll.bind(_, -1, range));
      case Explode(UpTo(times), range): rolls.map(explodeRoll.bind(_, times, range));
      case Reroll(Always, range): rolls.map(rerollRoll.bind(_, -1, range));
      case Reroll(UpTo(times), range): rolls.map(rerollRoll.bind(_, times, range));
    };
  }

  function explodeRoll(roll: DieResult<Result>, times: Int, range: Range): DiceResultMapped<Result> {
    var acc = rollRange(roll, times, range);
    return acc.length == 1 ? Normal(acc[0]) : Exploded(acc);
  }

  function rerollRoll(roll: DieResult<Result>, times: Int, range: Range): DiceResultMapped<Result> {
    var acc = rollRange(roll, times, range);
    return acc.length == 1 ? Normal(acc[0]) : Rerolled(acc);
  }

  function rollRange(roll: DieResult<Result>, times: Int, range: Range) {
    var acc = [roll],
        curr = roll;
    while(times != 0 && matchRange(curr.result, range)) {
      curr = { result: algebra.die(curr.sides), sides: curr.sides };
      acc.push(curr);
      times--;
    }
    return acc;
  }

  function matchRange(r: Result, range: Range): Bool {
    return switch range {
      case Exact(value):
        algebra.compareToSides(r, value) == 0;
      case Between(minInclusive, maxInclusive):
        algebra.compareToSides(r, minInclusive) >= 0 && algebra.compareToSides(r, maxInclusive) <= 0;
      case ValueOrMore(value):
        algebra.compareToSides(r, value) >= 0;
      case ValueOrLess(value):
        algebra.compareToSides(r, value) <= 0;
      case Composite(ranges):
        ranges.reduce(function(acc, currRange) {
          return acc || matchRange(r, currRange);
        }, false);
    };
  }

  function keepMappedRolls(rolls: Array<DiceResultMapped<Result>>): Array<DieResult<Result>> {
    return rolls.flatMap(function(r) return switch r {
      case Rerolled(rerolls): [rerolls.last()];
      case Exploded(explosions): explosions;
      case Normal(roll): [roll];
    });
  }

  function filterRolls(rolls: Array<RollResult<Result>>, filter: DiceFilter): Array<DieResultFilter<Result>> {
      var ranked = rolls.rank(function(a, b) {
        return algebra.compare(getResult(a), getResult(b));
      }, true);
      var f = switch filter {
        case Drop(Low, value):  function(i, l) return i >= value;
        case Drop(High, value): function(i, l) return i <  l - value;
        case Keep(Low, value):  function(i, l) return i < value;
        case Keep(High, value): function(i, l) return i >= l - value;
      };
      return rolls.mapi(function(roll, i) {
        return if(f(ranked[i], ranked.length))
          Keep(roll);
        else
          Discard(roll);
      });
  }

  function keepFilteredRolls(rolls: Array<DieResultFilter<Result>>) {
    return rolls.filterMap(function(roll) return switch roll {
      case Keep(r): Some(r);
      case Discard(_): None;
    });
  }

  function reduceRolls(rolls: Array<RollResult<Result>>, reducer: DiceReducer)
    return reduceResults(getRollResults(rolls), reducer);

  function reduceResults(results: Array<Result>, reducer: DiceReducer)
    return switch reducer {
      case Average:
          algebra.average(results);
        case Sum:
          results.reduce(algebra.sum, algebra.zero);
        case Min:
          results.order(algebra.compare).shift();
        case Max:
          results.order(algebra.compare).pop();
    };

  function getRollResults(rolls: Array<RollResult<Result>>)
    return rolls.map(getResult);
}
