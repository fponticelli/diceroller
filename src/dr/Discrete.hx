package dr;

import thx.Tuple;

// We model discrete distributions as pairs of (integer) weights and values
class Discrete {
  public var weightedValues(default, null): Array<Tuple2<Int, Float>> = [];

  // Standard constructor
  function new(weights: Array<Int>, values: Array<Float>) {
    for(i in 0...weights.length)
      weightedValues[i] = new Tuple2(weights[i], values[i]);
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
    return [for (i in 0...length()) weightedValues[i]._0];

  public function values(): Array<Float>
    return [for (i in 0...length()) weightedValues[i]._1];

  public function probabilities(): Array<Float> {
    var sum: Int = 0;
    for(i in 0...length())
      sum += weightedValues[i]._0;
    return [for (i in 0...length()) weightedValues[i]._0 / sum];
  }

  // Internal utility function. Call this before any returns of Discrete
  // After calling, weightedValues will have no repeated tuples, no zero
  // or negative weights and will be sorted by value
  function compact() {
    weightedValues.sort(compare);
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
    weightedValues[0] = new Tuple2(old_weights[0], old_values[0]);

    for(i in 1...old_weights.length)
      if(weightedValues[k]._1 == old_values[i])
        weightedValues[k] = new Tuple2(weightedValues[k]._0 + old_weights[i], weightedValues[k]._1);
      else {
        k++;
        weightedValues[k] = new Tuple2(old_weights[i], old_values[i]);
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
        weights[k] = this.weightedValues[i]._0 * other.weightedValues[j]._0;
        values[k] = f(this.weightedValues[i]._1, other.weightedValues[j]._1);
        k++;
      }
    return new Discrete(weights, values);
  }

  public function alwaysResample(x: Array<Float>) {
  // We set the weights of values in x to zero and let
  // compact (inside the constructor) remove them
    var weights: Array<Int> = this.weights();
    for(i in 0...this.length())
      for(j in 0...x.length)
        if(weightedValues[i]._1 == x[j])
          weights[i] = 0;
    return new Discrete(weights, this.values());
  }

  // Comparison function for sorting. Used in compact
  static function compare(x: Tuple2<Int, Float>, y: Tuple2<Int, Float>): Int
    return if(x._1 == y._1) 0 else if(x._1 < y._1) -1 else 1;
}
