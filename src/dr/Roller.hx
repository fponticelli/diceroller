package dr;

using thx.Arrays;
using thx.Arrays.ArrayInts;
using thx.Functions;
using thx.Ints;
import dr.DiceExpression;
import dr.RollResult;
import dr.RollResultExtensions.getResult;

class Roller {
  var dieRoll: Roll;
  public function new(dieRoll: Roll)
    this.dieRoll = dieRoll;

  public function roll(expr: DiceExpression): RollResult {
    return switch expr {
      case Die(sides):
        OneResult({ result: dieRoll(sides), sides: sides });
      case Literal(value):
        LiteralResult(value, value);
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
        var rolls = dice.map.fn({ result: dieRoll(_), sides: _ }),
            mapped = mapRolls(rolls, functor),
            keepMappedRolls = keepMappedRolls(mapped),
            result = reduceRolls(keepMappedRolls.map(OneResult), reducer);
        DiceReduceResult(DiceMapeableResult(mapped, functor), reducer, result);
      case BinaryOp(op, a, b):
        var ra = roll(a),
            rb = roll(b);
        switch op {
          case Sum:
            BinaryOpResult(Sum, ra, rb, getResult(ra) + getResult(rb));
          case Difference:
            BinaryOpResult(Difference, ra, rb, getResult(ra) - getResult(rb));
          case Division:
            BinaryOpResult(Division, ra, rb, Math.round(getResult(ra) / getResult(rb)));
          case Multiplication:
            BinaryOpResult(Multiplication, ra, rb, getResult(ra) * getResult(rb));
        }
      case UnaryOp(Negate, a):
        var ra = roll(a);
        UnaryOpResult(Negate, ra, -getResult(ra));
    };
  }

  function mapRolls(rolls: Array<DieResult>, functor: DiceFunctor): Array<DiceResultMapped> {
    return switch functor {
      case Explode(Always, range): rolls.map(explodeRoll.bind(_, -1, range));
      case Explode(UpTo(times), range): rolls.map(explodeRoll.bind(_, times, range));
      case Reroll(Always, range): rolls.map(rerollRoll.bind(_, -1, range));
      case Reroll(UpTo(times), range): rolls.map(rerollRoll.bind(_, times, range));
    };
  }

  function explodeRoll(roll: DieResult, times: Int, range: Range): DiceResultMapped {
    var acc = rollRange(roll, times, range);
    return acc.length == 1 ? Normal(acc[0]) : Exploded(acc);
  }

  function rerollRoll(roll: DieResult, times: Int, range: Range): DiceResultMapped {
    var acc = rollRange(roll, times, range);
    return acc.length == 1 ? Normal(acc[0]) : Rerolled(acc);
  }

  function rollRange(roll: DieResult, times: Int, range: Range) {
    var acc = [roll],
        curr = roll;
    while(times != 0 && matchRange(curr.result, range)) {
      curr = { result: dieRoll(curr.sides), sides: curr.sides };
      acc.push(curr);
      times--;
    }
    return acc;
  }

  function matchRange(r: Int, range: Range): Bool {
    return switch range {
      case Exact(value):
        Ints.compare(r, value) == 0;
      case Between(minInclusive, maxInclusive):
        Ints.compare(r, minInclusive) >= 0 && Ints.compare(r, maxInclusive) <= 0;
      case ValueOrMore(value):
        Ints.compare(r, value) >= 0;
      case ValueOrLess(value):
        Ints.compare(r, value) <= 0;
      case Composite(ranges):
        ranges.reduce(function(acc, currRange) {
          return acc || matchRange(r, currRange);
        }, false);
    };
  }

  function keepMappedRolls(rolls: Array<DiceResultMapped>): Array<DieResult> {
    return rolls.flatMap(function(r) return switch r {
      case Rerolled(rerolls): [rerolls.last()];
      case Exploded(explosions): explosions;
      case Normal(roll): [roll];
    });
  }

  public static function filterf(filter: DiceFilter)
    return switch filter {
      case Drop(Low, value):  function(res: Float, length: Int) return res >= value;
      case Drop(High, value): function(res: Float, length: Int) return res <  length - value;
      case Keep(Low, value):  function(res: Float, length: Int) return res < value;
      case Keep(High, value): function(res: Float, length: Int) return res >= length - value;
    };

  public static function reducef(reducer: DiceReducer)
    return switch reducer {
      case Sum: function(arr: Array<Float>) return arr.sum();
      case Average: function(arr: Array<Float>) return Math.round(arr.average());
      case Min: function(arr: Array<Float>) return arr.min();
      case Max: function(arr: Array<Float>) return arr.max();
    };

  function filterRolls(rolls: Array<RollResult>, filter: DiceFilter): Array<DieResultFilter> {
      var ranked = rolls.rank(function(a, b) {
        return Ints.compare(getResult(a), getResult(b));
      }, true);
      var f = filterf(filter);
      return rolls.mapi(function(roll, i) {
        return if(f(ranked[i], ranked.length))
          Keep(roll);
        else
          Discard(roll);
      });
  }

  function keepFilteredRolls(rolls: Array<DieResultFilter>) {
    return rolls.filterMap(function(roll) return switch roll {
      case Keep(r): Some(r);
      case Discard(_): None;
    });
  }

  function reduceRolls(rolls: Array<RollResult>, reducer: DiceReducer): Int
    return reduceResults(getRollResults(rolls), reducer);

  function reduceResults(results: Array<Int>, reducer: DiceReducer): Int
    return switch reducer {
      case Average:
          Math.round(ArrayInts.average(results));
        case Sum:
          results.reduce(function(a, b) return a + b, 0);
        case Min:
          ArrayInts.min(results);
        case Max:
          ArrayInts.max(results);
    };

  function getRollResults(rolls: Array<RollResult>)
    return rolls.map(getResult);
}
