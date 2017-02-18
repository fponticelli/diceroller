package dapi;

import thx.Tuple;

// We model discrete distributions as pairs of (integer) weights and values
class Discrete {
  public var weighted_values(default, null): Array<Tuple2<Int, Float>> = [];

  // Standard constructor
  function new(weights: Array<Int>, values: Array<Float>) {
    for(i in 0...weights.length)
      weighted_values[i] = new Tuple2(weights[i], values[i]);
    compact();
  }

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
  function compact() {
    weighted_values.sort(compare);
    var old_weights = weights();
    var old_values = values();
    weighted_values = [];

    weighted_values[0] = new Tuple2(old_weights[0], old_values[0]);
    var j: Int = 0;
    for(i in 1...old_weights.length)
      if(weighted_values[j]._1 == old_values[i])
        weighted_values[j] = new Tuple2(weighted_values[j]._0 + old_weights[i], weighted_values[j]._1);
      else {
        j++;
        weighted_values[j] = new Tuple2(old_weights[i], old_values[i]);
      }
  }

  // Algebriac functions
  public function unary(f: Float -> Float): Discrete
    return new Discrete(weights(), values().map(f));

  public function binary(other: Discrete, f: Float -> Float -> Float): Discrete {
    var m = this.length() * other.length();
    var weights: Array<Int> = [for (i in 0...m) 0];
    var values: Array<Float> = [for (i in 0...m) 0.0];
    var k = 0;
    for(i in 0...this.length())
      for(j in 0...other.length()) {
        weights[k] = this.weighted_values[i]._0 * other.weighted_values[j]._0;
        values[k] = f(this.weighted_values[i]._1, other.weighted_values[j]._1);
        k++;
      }
    return new Discrete(weights, values);
  }

  // Comparison function for sorting. Used in compact
  static function compare(x: Tuple2<Int, Float>, y: Tuple2<Int, Float>): Int
    return if(x._1 == y._1) 0 else if(x._1 < y._1) -1 else 1;
}
