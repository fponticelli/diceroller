package dr;

class DiscreteAlgebra implements Algebra<Discrete> {
  public var zero(default, null) = Discrete.empty;
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
    return a.binary(b, function(a,b) return Std.int(a / b));
  public function compare(a: Discrete, b: Discrete)
    return 0; // TODO
  public function compareToSides(a: Discrete, b: Sides): Int
    return 0; // TODO
  public function average(arr: Array<Discrete>): Discrete
    return Discrete.literal(0); // TODO
  public function ofLiteral(v: Int)
    return Discrete.literal(v);
}