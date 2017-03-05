package dr;

using thx.Arrays;
using thx.Functions;
import dr.Discrete;
import dr.DiceExpression;

class Probabilities {
  public function new() {}

  public function roll(expr: DiceExpression): Discrete {
    return switch expr {
      case Die(sides):
        Discrete.die(sides);
      case Literal(value):
        Discrete.literal(value);
      case DiceReduce(DiceExpressions(exprs), Sum):
        exprs.map(roll).reduce(function(a: Discrete, b: Discrete) return a.add(b), Discrete.zero);
      case DiceReduce(DiceExpressions(exprs), Average):
        Discrete.average(exprs.map(roll));
      case DiceReduce(DiceExpressions(exprs), Min):
        Discrete.min(exprs.map(roll));
      case DiceReduce(DiceExpressions(exprs), Max):
        Discrete.max(exprs.map(roll));
      case DiceReduce(DiceListWithFilter(DiceArray(dice), filter), reducer):
        var f = Roller.filterf(filter);
        var agg = Roller.reducef(reducer);
        return Discrete.apply(dice.map.fn(Die(_)).map(roll), function(values) {
          trace(values.filter(f.bind(_, values.length)));
          return agg(values.filter(f.bind(_, values.length))); // TODO
        });
      case DiceReduce(DiceListWithFilter(DiceExpressions(dice), filter), reducer):
        var f = Roller.filterf(filter);
        var agg = Roller.reducef(reducer);
        return Discrete.apply(dice.map(roll), function(values) {
          return agg(values.filter(f.bind(_, values.length)));
        });
      case DiceReduce(DiceListWithMap(dice, Explode(times, range)), Sum):
        Discrete.apply(dice.map.fn(Die(_)).map(roll), function(arr) {
          return arr[0]; // TODO
        });
      case DiceReduce(DiceListWithMap(dice, Reroll(times, range)), Sum):
        null; // TODO
      case DiceReduce(DiceListWithMap(dice, Explode(times, range)), Average):
        null; // TODO
      case DiceReduce(DiceListWithMap(dice, Reroll(times, range)), Average):
        null; // TODO
      case DiceReduce(DiceListWithMap(dice, Explode(times, range)), Min):
        null; // TODO
      case DiceReduce(DiceListWithMap(dice, Reroll(times, range)), Min):
        null; // TODO
      case DiceReduce(DiceListWithMap(dice, Explode(times, range)), Max):
        null; // TODO
      case DiceReduce(DiceListWithMap(dice, Reroll(times, range)), Max):
        null; // TODO
      case BinaryOp(Sum, a, b):
        roll(a).add(roll(b));
      case BinaryOp(Difference, a, b):
        roll(a).subtract(roll(b));
      case BinaryOp(Multiplication, a, b):
        roll(a).multiply(roll(b));
      case BinaryOp(Division, a, b):
        roll(a).divide(roll(b));
      case UnaryOp(Negate, a):
        roll(a).negate();
    };
  }

  // function mapRolls(rolls: Array<DieResult<Discrete>>, functor: DiceFunctor): Array<DiceResultMapped<Discrete>> {
  //   return switch functor {
  //     case Explode(Always, range): rolls.map(explodeRoll.bind(_, -1, range));
  //     case Explode(UpTo(times), range): rolls.map(explodeRoll.bind(_, times, range));
  //     case Reroll(Always, range): rolls.map(rerollRoll.bind(_, -1, range));
  //     case Reroll(UpTo(times), range): rolls.map(rerollRoll.bind(_, times, range));
  //   };
  // }

  // function explodeRoll(roll: DieResult<Discrete>, times: Int, range: Range): DiceResultMapped<Discrete> {
  //   var acc = rollRange(roll, times, range);
  //   return acc.length == 1 ? Normal(acc[0]) : Exploded(acc);
  // }

  // function rerollRoll(roll: DieResult<Discrete>, times: Int, range: Range): DiceResultMapped<Discrete> {
  //   var acc = rollRange(roll, times, range);
  //   return acc.length == 1 ? Normal(acc[0]) : Rerolled(acc);
  // }

  // function rollRange(roll: DieResult<Discrete>, times: Int, range: Range) {
  //   var acc = [roll],
  //       curr = roll;
  //   while(times != 0 && matchRange(curr.result, range)) {
  //     curr = { result: algebra.die(curr.sides), sides: curr.sides };
  //     acc.push(curr);
  //     times--;
  //   }
  //   return acc;
  // }

  // function matchRange(r: Result, range: Range): Bool {
  //   return switch range {
  //     case Exact(value):
  //       algebra.compareToSides(r, value) == 0;
  //     case Between(minInclusive, maxInclusive):
  //       algebra.compareToSides(r, minInclusive) >= 0 && algebra.compareToSides(r, maxInclusive) <= 0;
  //     case ValueOrMore(value):
  //       algebra.compareToSides(r, value) >= 0;
  //     case ValueOrLess(value):
  //       algebra.compareToSides(r, value) <= 0;
  //     case Composite(ranges):
  //       ranges.reduce(function(acc, currRange) {
  //         return acc || matchRange(r, currRange);
  //       }, false);
  //   };
  // }

  // function keepMappedRolls(rolls: Array<DiceResultMapped<Discrete>>): Array<DieResult<Discrete>> {
  //   return rolls.flatMap(function(r) return switch r {
  //     case Rerolled(rerolls): [rerolls.last()];
  //     case Exploded(explosions): explosions;
  //     case Normal(roll): [roll];
  //   });
  // }

  // function filterRolls(rolls: Array<Discrete>, filter: DiceFilter): Array<DieResultFilter<Discrete>> {
  //     var ranked = rolls.rank(function(a, b) {
  //       return algebra.compare(getResult(a), getResult(b));
  //     }, true);
  //     var f = switch filter {
  //       case Drop(Low, value):  function(i, l) return i >= value;
  //       case Drop(High, value): function(i, l) return i <  l - value;
  //       case Keep(Low, value):  function(i, l) return i < value;
  //       case Keep(High, value): function(i, l) return i >= l - value;
  //     };
  //     return rolls.mapi(function(roll, i) {
  //       return if(f(ranked[i], ranked.length))
  //         Keep(roll);
  //       else
  //         Discard(roll);
  //     });
  // }

  // function keepFilteredRolls(rolls: Array<DieResultFilter<Discrete>>) {
  //   return rolls.filterMap(function(roll) return switch roll {
  //     case Keep(r): Some(r);
  //     case Discard(_): None;
  //   });
  // }

  // function reduceRolls(rolls: Array<Discrete>, reducer: DiceReducer)
  //   return reduceResults(getRollResults(rolls), reducer);

  // function reduceResults(results: Array<Discrete>, reducer: DiceReducer)
  //   return switch reducer {
  //     case Average:
  //         algebra.average(results);
  //       case Sum:
  //         results.reduce(algebra.sum, algebra.zero);
  //       case Min:
  //         algebra.min(results);
  //       case Max:
  //         algebra.max(results);
  //   };

  // function getRollResults(rolls: Array<Discrete>)
  //   return rolls.map(getResult);
}
