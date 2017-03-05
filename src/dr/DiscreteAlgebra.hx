package dr;

using thx.Arrays;
using thx.Floats;

class DiscreteAlgebra implements Algebra<Discrete> {
  public var zero(default, null) = Discrete.zero;
  public function new() {}
  public function die(sides: Sides)
    return Discrete.die(sides);
  public function sum(a: Discrete, b: Discrete)
    return a.binary(b, function(a,b) return a + b);
  public function subtract(a: Discrete, b: Discrete)
    return a.binary(b, function(a,b) return a - b);
  public function negate(a: Discrete)
    return a.unary(function(a) return -a);
  public function multiply(a: Discrete, b: Discrete)
    return a.binary(b, function(a,b) return a * b);
  public function divide(a: Discrete, b: Discrete)
    return a.binary(b, function(a,b) return Math.ceil(a / b));
  public function average(arr: Array<Discrete>): Discrete
    return Discrete.apply(arr, function(d) {
      return Math.round(d.average());
    });
  public function min(arr: Array<Discrete>): Discrete
    return Discrete.apply(arr, function(d) {
      return Math.round(d.order(Floats.compare).shift());
    });
  public function max(arr: Array<Discrete>): Discrete
    return Discrete.apply(arr, function(d) {
      return Math.round(d.order(Floats.compare).pop());
    });

  public function compare(a: Discrete, b: Discrete): Int {
    var d = a.binary(b, function(a,b) return a - b);
    trace(d);
    return 0;
  }
  public function compareToSides(a: Discrete, b: Sides): Int
    return 0; // TODO
  public function ofLiteral(v: Int)
    return Discrete.literal(v);
}
