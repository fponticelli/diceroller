package dr;

import thx.Tuple;
import dr.BoxLattice;

// We model discrete distributions as pairs of (integer) weights and values
class Discrete {
  public var weighted_values(default, null): Array<Tuple2<Int, Float>> = [];

  // Standard constructor
  function new(weights: Array<Int>, values: Array<Float>) {
    for(i in 0...weights.length)
      weighted_values[i] = new Tuple2(weights[i], values[i]);
    compact();
  }

  public static var zero(default, null): Discrete = literal(0);

  public static function literal(n: Int) // TODO ?
    return new Discrete([1], [n]);

  // Create a new Discrete representing a die with specified number of faces
  // and standard numbering (1...n). E.g., Discrete.die(6) creates a d6
  public static function die(n: Int)
    return new Discrete([for (i in 0...n) 1], [for (i in 0...n) i + 1]);

  // Public getter methods
  public inline function length(): Int
    return weighted_values.length;

  public function weights(): Array<Int>
    return [for (i in 0...length()) weighted_values[i]._0];

  public function values(): Array<Float>
    return [for (i in 0...length()) weighted_values[i]._1];

  public function probabilities(): Array<Float> {
    var sum: Int = 0;
    for(i in 0...length())
      sum += weighted_values[i]._0;
    return [for (i in 0...length()) weighted_values[i]._0 / sum];
  }

  // Internal utility function. Call this before any returns of Discrete
  // After calling, weighted_values will have no repeated tuples, no zero
  // or negative weights and will be sorted by value
  function compact() {
    weighted_values.sort(compare);
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
    weighted_values = [];
    weighted_values[0] = new Tuple2(old_weights[0], old_values[0]);

    for(i in 1...old_weights.length)
      if(weighted_values[k]._1 == old_values[i])
        weighted_values[k] = new Tuple2(weighted_values[k]._0 + old_weights[i], weighted_values[k]._1);
      else {
        k++;
        weighted_values[k] = new Tuple2(old_weights[i], old_values[i]);
      }
  }

  // Algebriac functions
  public function unary(f: Float -> Float): Discrete
    return new Discrete(weights(), values().map(f));

  public function binary(other: Discrete, f: Float -> Float -> Float): Discrete
    return apply([this, other], function (a: Array<Float>):Float { return f(a[0], a[1]);} );


  public function always_resample(x: Array<Float>) {
  // We set the weights of values in x to zero and let
  // compact (inside the constructor) remove them
    var weights: Array<Int> = this.weights();
    for(i in 0...this.length())
      for(j in 0...x.length)
        if(weighted_values[i]._1 == x[j])
          weights[i] = 0;
    return new Discrete(weights, this.values());
  }

  public static function apply(operands: Array<Discrete>, operator: Array<Float> -> Float): Discrete {
    var weighted_values = operands.map(function (discrete: Discrete) { return discrete.weighted_values; });
    var bl = new BoxLattice(weighted_values, Left(0));
    var f = function(headers: Array<Tuple2<Int, Float>>): Tuple2<Int, Float> {
      var headervalues: Array<Float> = [];
      var product = 1;
      for (d in 0...headers.length) {
        product *= headers[d]._0;
        headervalues[d] = headers[d]._1;
      }
      return new Tuple2(product, operator(headervalues));
    }
    var x = bl.mapheaderstocells(f);
    var weights = x.flatten().map(function (pair: Tuple2<Int, Float>) { return pair._0; } );
    var values = x.flatten().map(function (pair: Tuple2<Int, Float>) { return pair._1; } );
    return new Discrete(weights, values);
  }

  // Comparison function for sorting. Used in compact
  static function compare(x: Tuple2<Int, Float>, y: Tuple2<Int, Float>): Int
    return if(x._1 == y._1) 0 else if(x._1 < y._1) -1 else 1;
}
