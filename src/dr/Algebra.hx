package dr;

interface Algebra<T> {
  var zero(default, null): T;
  function die(sides: Sides): T;
  function sum(a: T, b: T): T;
  function subtract(a: T, b: T): T;
  function negate(a: T): T;
  function multiply(a: T, b: T): T;
  function divide(a: T, b: T): T;
  function compare(a: T, b: T): Int;
  function compareToSides(a: T, b: Sides): Int;
  function average(arr: Array<T>): T;
  function ofLiteral(v: Int): T;
}

class IntAlgebra implements Algebra<Int> {
  public var zero(default, null) = 0;
  var roll: Sides -> Int;
  public function new(roll: Sides -> Int)
    this.roll = roll;
  public function die(sides: Sides)
    return roll(sides);
  public function sum(a: Int, b: Int)
    return a + b;
  public function subtract(a: Int, b: Int)
    return a - b;
  public function negate(a: Int)
    return -a;
  public function multiply(a: Int, b: Int)
    return a * b;
  public function divide(a: Int, b: Int)
    return Math.ceil(a / b);
  public function compare(a: Int, b: Int)
    return thx.Ints.compare(a, b);
  public function compareToSides(a: Int, b: Sides)
    return thx.Ints.compare(a, b);
  public function average(arr: Array<Int>): Int
    return Math.ceil(thx.Arrays.ArrayInts.average(arr));
  public function ofLiteral(v: Int)
    return v;
}