package dapi;

import thx.Unit;

class Die<T> {
  public static function withSides(sides: Int): Die<Unit>
    return new Die(sides, Unit.unit);

  public var sides(default, null): Int;
  public var meta(default, null): T;

  public function new(sides: Int, meta: T) {
    this.sides = sides;
    this.meta = meta;
  }

  public function roll(random: Int -> Int): Die<DiceResultMeta<T>> {
    return new Die(sides, {
      result: random(sides),
      meta: meta
    });
  }
}