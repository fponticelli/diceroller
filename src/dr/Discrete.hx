package dr;

import dr.BoxLattice;
import thx.format.NumberFormat;
using thx.Strings;
using thx.Arrays;
using thx.Floats;

class WeightedValue {
  // Comparison function for sorting. Used in compact
  public static function compare(x: WeightedValue, y: WeightedValue): Int
    return if(x.weight == y.weight) 0 else if(x.weight < y.weight) -1 else 1;

  public var value: Float;
  public var weight: Int;
  public function new(value: Float, weight: Int) {
    this.value = value;
    this.weight = weight;
  }
}

// We model discrete distributions as pairs of (integer) weights and values
class Discrete {
  public var weightedValues(default, null): Array<WeightedValue> = [];

  // Standard constructor
  function new(weights: Array<Int>, values: Array<Float>) {
    for(i in 0...weights.length)
      weightedValues[i] = new WeightedValue(values[i], weights[i]);
    compact();
  }

  public static var zero(default, null): Discrete = literal(0);
  public static function literal(n: Int)
    return new Discrete([1], [n]);

  // Create a new Discrete representing a die with specified number of faces
  // and standard numbering (1...n). E.g., Discrete.die(6) creates a d6
  public static function die(n: Int)
    return new Discrete([for (i in 0...n) 1], [for (i in 0...n) i + 1]);

  // Public getter methods
  public inline function length(): Int
    return weightedValues.length;

  public function weights(): Array<Int>
    return [for (i in 0...length()) weightedValues[i].weight];

  public function values(): Array<Float>
    return [for (i in 0...length()) weightedValues[i].value];

  public function probabilities(): Array<Float> {
    var sum: Int = 0;
    for(i in 0...length())
      sum += weightedValues[i].weight;
    return [for (i in 0...length()) weightedValues[i].weight / sum];
  }

  // Internal utility function. Call this before any returns of Discrete
  // After calling, weightedValues will have no repeated tuples, no zero
  // or negative weights and will be sorted by value
  function compact() {
    weightedValues.sort(WeightedValue.compare);
    var maybezero_weights = weights();
    var maybezero_values = values();
    var old_weights = [];
    var old_values = [];
    var j: Int = 0;

    // Remove zero or negative weights
    for (i in 0...maybezero_weights.length) {
      if(maybezero_weights[i] > 0) {
        old_weights[j] = maybezero_weights[i];
        old_values[j] = maybezero_values[i];
        j++;
      }
    }

    // Consolidate weights with the same values
    var k: Int = 0;
    weightedValues = [];
    weightedValues[0] = new WeightedValue(old_values[0], old_weights[0]);

    for(i in 1...old_weights.length)
      if(weightedValues[k].value == old_values[i])
        weightedValues[k] = new WeightedValue(weightedValues[k].value, weightedValues[k].weight + old_weights[i]);
      else {
        k++;
        weightedValues[k] = new WeightedValue(old_values[i], old_weights[i]);
      }
  }

  public function map(f: Float -> Float): Discrete
    return new Discrete(weights(), values().map(f));

  // Algebriac functions
  public function negate(): Discrete
    return map(function(v) return -v);
  public function binary(other: Discrete, f: Float -> Float -> Float): Discrete
    return apply([this, other], function (a: Array<Float>):Float { return f(a[0], a[1]);} );
  public function add(b: Discrete)
    return binary(b, function(a,b) return a + b);
  public function subtract(b: Discrete)
    return binary(b, function(a,b) return a - b);
  public function multiply(b: Discrete)
    return binary(b, function(a,b) return a * b);
  public function divide(b: Discrete)
    return binary(b, function(a,b) return Math.round(a / b));
  public static function average(arr: Array<Discrete>): Discrete
    return Discrete.apply(arr, function(d) {
      return Math.round(d.average());
    });
  public static function min(arr: Array<Discrete>): Discrete
    return Discrete.apply(arr, function(d) {
      return Math.round(d.order(Floats.compare).shift());
    });
  public static function max(arr: Array<Discrete>): Discrete
    return Discrete.apply(arr, function(d) {
      return Math.round(d.order(Floats.compare).pop());
    });

  public function alwaysResample(x: Array<Float>) {
  // We set the weights of values in x to zero and let
  // compact (inside the constructor) remove them
    var weights: Array<Int> = this.weights();
    for(i in 0...this.length())
      for(j in 0...x.length)
        if(weightedValues[i].value == x[j])
          weights[i] = 0;
    return new Discrete(weights, this.values());
  }

  public static function apply(operands: Array<Discrete>, operator: Array<Float> -> Float): Discrete {
    var weightedValues = operands.map(function (discrete: Discrete) { return discrete.weightedValues; });
    var bl = new BoxLattice(weightedValues, Left(0));
    var f = function(headers: Array<WeightedValue>): WeightedValue {
      var headervalues: Array<Float> = [];
      var product = 1;
      for (d in 0...headers.length) {
        product *= headers[d].weight;
        headervalues[d] = headers[d].value;
      }
      return new WeightedValue(operator(headervalues), product);
    }
    var x = bl.mapheaderstocells(f);
    var weights = x.flatten().map(function (wv: WeightedValue) { return wv.weight; } );
    var values = x.flatten().map(function (wv: WeightedValue) { return wv.value; } );
    return new Discrete(weights, values);
  }

  public function toString() {
    var format = NumberFormat.integer.bind(_, null);
    var pad = values().reduce(function(max, curr) {
      var v = format(curr).length;
      return thx.Ints.max(v, max);
    }, 0);
    return 'probabilities:\n' + values().zip(probabilities()).map(function(vp) {
      return format(vp._0).lpad(" ", pad) + ": " + NumberFormat.percent(vp._1, 2);
    }).join("\n");
  }
}
