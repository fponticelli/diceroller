package dr;

using thx.Arrays;
using thx.ReadonlyArray;
using thx.Ints;
using thx.Iterators;
using thx.Functions;
import dr.DiceExpression;

class Sample {
  public static var empty(default, null) = new Sample([]);
  public static var zero(default, null) = new Sample([0]);
  public static var one(default, null) = new Sample([1]);

  public static function literal(v: Int)
    return new Sample([v]);

  public static function die(v: Int)
    return new Sample([for(i in 1...v+1) i]);

  public static function sum(samples: Array<Sample>): Sample
    return fold(samples, function(a: Sample, b: Sample) return a.add(b));

  public static function average(samples: Array<Sample>): Sample
    return sum(samples).divide(literal(samples.length));

  public static function apply(a: Sample, b: Sample, f: Int -> Int -> Int)
    return a.flatMap(function(as) {
      return b.map(function(bs) return f(as, bs));
    });

  public static function fold(samples: Array<Sample>, f: Sample -> Sample -> Sample) {
    if(samples.length == 0) return empty;
    // samples = samples.copy();
    // this is a poor man reduce, but reduce generates a Maximum call stack exception
    var curr = samples[0];
    for(i in 1...samples.length)
      curr = f(curr, samples[i]);
    return curr;
  }

  public static function filterRolls(arr: Array<Sample>, f: Array<Int> -> Array<Int>): Array<Sample> {
    var a = arr.map.fn(_.values);
    var c = a.crossMulti().map(Arrays.order.bind(_, Ints.compare));
    var m = c.map(f);
    return m.rotate().map(Sample.new);
  }

  public static function minSeries(samples: Array<Sample>): Sample
    return fold(samples, function(a, b) return a.min(b));

  public static function maxSeries(samples: Array<Sample>): Sample
    return fold(samples, function(a, b) return a.max(b));

  public var values(get, never): ReadonlyArray<Int>;
  var _values: ReadonlyArray<Int>;
  public function new(values: ReadonlyArray<Int>) {
    this._values = values;
  }

  public function aggregate() {
    var map = new Map();
    for(v in values) {
      if(map.exists(v))
        map.set(v, map.get(v) + 1);
      else
        map.set(v, 1);
    }
    return map;
  }

  public function pairs() {
    var map = aggregate();
    var keys = map.keys().toArray();
    return keys.map.fn({ roll: _, instances: map.get(_) });
  }

  public function probabilities() {
    var pairs = pairs();
    var total = pairs.reduce(function(a, b) return a + b.instances, 0);
    return pairs.map.fn({ roll: _.roll, probability: _.instances / total });
  }

  public function toString() {
    return "{" + probabilities().map.fn(_.roll + ":" + Math.round(_.probability * 10000)/100+"%").join(", ") + "}";
  }

  public function map(f: Int -> Int): Sample
    return new Sample(values.map(f));

  public function flatMap(f: Int -> Sample): Sample
    return new Sample(values.map(f).map.fn(_.values).flatten());

  public function add(other: Sample): Sample
    return apply(this, other, function(a, b) return a + b);

  public function subtract(other: Sample): Sample
    return apply(this, other, function(a, b) return a - b);

  public function multiply(other: Sample): Sample
    return apply(this, other, function(a, b) return a * b);

  public function divide(other: Sample): Sample
    return apply(this, other, function(a, b) return Math.round(a / b));

  public function max(other: Sample): Sample
    return apply(this, other, Ints.max);

  public function min(other: Sample): Sample
    return apply(this, other, Ints.min);

  public function negate(): Sample
    return map(function(v) return -v);

  function get_values(): ReadonlyArray<Int>
    return _values.order(Ints.compare);
}

class DiceProbabilities {
  public function new() {}

  public function roll(expr: DiceExpression): Sample {
    trace(expr);
    return switch expr {
      case Die(sides):
        Sample.die(sides);
      case Literal(value):
        Sample.literal(value);
    case DiceReduce(DiceExpressions(exprs), Sum):
      Sample.sum(exprs.map(roll));
    case DiceReduce(DiceExpressions(exprs), Average):
      Sample.average(exprs.map(roll));
    case DiceReduce(DiceExpressions(exprs), Min):
      Sample.minSeries(exprs.map(roll));
    case DiceReduce(DiceExpressions(exprs), Max):
      Sample.maxSeries(exprs.map(roll));
    case DiceReduce(DiceListWithFilter(DiceArray(dice), Drop(Low, value)), Sum):
      trace("HERE");
      var s = dice.map.fn(Die(_)).map(roll);
      var f = Sample.filterRolls(s, function(a) {
        return a.slice(value, a.length);
      });
      Sample.sum(f);
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
case _: // TODO
  Sample.empty;
    }
  }

  //     case DiceReduce(DiceListWithFilter(DiceArray(dice), filter), reducer):
  //       var f = Roller.filterf(filter);
  //       var agg = Roller.reducef(reducer);
  //       return Sample.apply(dice.map.fn(Die(_)).map(roll), function(values) {
  //         trace(values.filter(f.bind(_, values.length)));
  //         return agg(values.filter(f.bind(_, values.length))); // TODO
  //       });
  //     case DiceReduce(DiceListWithFilter(DiceExpressions(dice), filter), reducer):
  //       var f = Roller.filterf(filter);
  //       var agg = Roller.reducef(reducer);
  //       return Sample.apply(dice.map(roll), function(values) {
  //         return agg(values.filter(f.bind(_, values.length)));
  //       });
  //     case DiceReduce(DiceListWithMap(dice, Explode(times, range)), Sum):
  //       Sample.apply(dice.map.fn(Die(_)).map(roll), function(arr) {
  //         return arr[0]; // TODO
  //       });
  //     case DiceReduce(DiceListWithMap(dice, Reroll(times, range)), Sum):
  //       null; // TODO
  //     case DiceReduce(DiceListWithMap(dice, Explode(times, range)), Average):
  //       null; // TODO
  //     case DiceReduce(DiceListWithMap(dice, Reroll(times, range)), Average):
  //       null; // TODO
  //     case DiceReduce(DiceListWithMap(dice, Explode(times, range)), Min):
  //       null; // TODO
  //     case DiceReduce(DiceListWithMap(dice, Reroll(times, range)), Min):
  //       null; // TODO
  //     case DiceReduce(DiceListWithMap(dice, Explode(times, range)), Max):
  //       null; // TODO
  //     case DiceReduce(DiceListWithMap(dice, Reroll(times, range)), Max):
  //       null; // TODO
  //   };
  // }

  // function mapRolls(rolls: Array<DieResult<Sample>>, functor: DiceFunctor): Array<DiceResultMapped<Sample>> {
  //   return switch functor {
  //     case Explode(Always, range): rolls.map(explodeRoll.bind(_, -1, range));
  //     case Explode(UpTo(times), range): rolls.map(explodeRoll.bind(_, times, range));
  //     case Reroll(Always, range): rolls.map(rerollRoll.bind(_, -1, range));
  //     case Reroll(UpTo(times), range): rolls.map(rerollRoll.bind(_, times, range));
  //   };
  // }

  // function explodeRoll(roll: DieResult<Sample>, times: Int, range: Range): DiceResultMapped<Sample> {
  //   var acc = rollRange(roll, times, range);
  //   return acc.length == 1 ? Normal(acc[0]) : Exploded(acc);
  // }

  // function rerollRoll(roll: DieResult<Sample>, times: Int, range: Range): DiceResultMapped<Sample> {
  //   var acc = rollRange(roll, times, range);
  //   return acc.length == 1 ? Normal(acc[0]) : Rerolled(acc);
  // }

  // function rollRange(roll: DieResult<Sample>, times: Int, range: Range) {
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

  // function keepMappedRolls(rolls: Array<DiceResultMapped<Sample>>): Array<DieResult<Sample>> {
  //   return rolls.flatMap(function(r) return switch r {
  //     case Rerolled(rerolls): [rerolls.last()];
  //     case Exploded(explosions): explosions;
  //     case Normal(roll): [roll];
  //   });
  // }

  // function filterRolls(rolls: Array<Sample>, filter: DiceFilter): Array<DieResultFilter<Sample>> {
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

  // function keepFilteredRolls(rolls: Array<DieResultFilter<Sample>>) {
  //   return rolls.filterMap(function(roll) return switch roll {
  //     case Keep(r): Some(r);
  //     case Discard(_): None;
  //   });
  // }

  // function reduceRolls(rolls: Array<Sample>, reducer: DiceReducer)
  //   return reduceResults(getRollResults(rolls), reducer);

  // function reduceResults(results: Array<Sample>, reducer: DiceReducer)
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

  // function getRollResults(rolls: Array<Sample>)
  //   return rolls.map(getResult);
}
