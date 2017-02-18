package probability;

import thx.Tuple;

// We model discrete distributions as pairs of (integer) weights and values
class Discrete {
  public var weighted_values(default, null): Array<Tuple2<Int, Float>>;

  // Standard constructor
  public function new(weights: Array<Int>, values: Array<Float>) {
    var n = weights.length;
    weighted_values = [for (i in 0...n) new Tuple2(0, 0.0)];
    for(i in 0...n)
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
    return [for (i in 0...length()) weighted_values[i].left];

  public function values(): Array<Float>
    return [for (i in 0...length()) weighted_values[i].right];

  public function probabilities(): Array<Float> {
    var sum: Int = 0;
    for(i in 0...length())
      sum += weighted_values[i].left;
    return [for (i in 0...length()) weighted_values[i].left / sum];
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
      if(weighted_values[j].right == old_values[i])
        weighted_values[j] = new Tuple2(weighted_values[j].left + old_weights[i], weighted_values[j].right);
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
        weights[k] = this.weighted_values[i].left * other.weighted_values[j].left;
        values[k] = f(this.weighted_values[i].right, other.weighted_values[j].right);
        k++;
      }
    return new Discrete(weights, values);
  }

  // Comparison function for sorting. Used in compact
  static function compare(x: Tuple2<Int, Float>, y: Tuple2<Int, Float>): Int
    return if(x.right == y.right) 0 else if(x.right < y.right) -1 else 1;
}
