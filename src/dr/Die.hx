package dr;

import thx.Unit;

class Die<T> {
  public static function withSides(sides: Int): Die<Unit>
    return new Die(sides, Unit.unit);

  public var sides(default, null): Int;
  public var result(default, null): T;

  public function new(sides: Int, result: T) {
    this.sides = sides;
    this.result = result;
  }

  public function roll<Result>(random: Sides -> Result): Die<Result>
    return new Die(sides, random(sides));

  public function toString()
    return "d" + (sides == 100 ? "%" : '$sides');

  public function toStringWithMeta(f: T -> String)
    return 'd$sides [${f(result)}]';
}