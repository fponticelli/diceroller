package dapi;

import dapi.DiceExpression;

class DiceDSL {
  public static function many<T>(dice: Int, die: Die<T>, meta: T): DiceExpression<T>
    return RollMany(RepeatDie(dice, die), meta);

  public static function dice<T>(dice: Array<Die<T>>, meta: T): DiceExpression<T>
    return RollMany(DiceList(dice), meta);

  public static function die<T>(sides: Int, meta: T): DiceExpression<T>
    return RollOne(new Die(sides, meta));

  public static function dropLow<T>(dice: Int, die: Die<T>, drop: Int, meta: T): DiceExpression<T>
    return RollAndDropLow(RepeatDie(dice, die), drop, meta);

  public static function keepHigh<T>(dice: Int, die: Die<T>, keep: Int, meta: T): DiceExpression<T>
    return RollAndKeepHigh(RepeatDie(dice, die), keep, meta);

  public static function explosive<T>(dice: Int, die: Die<T>, explodeOn: Int, meta: T): DiceExpression<T>
    return RollAndExplode(RepeatDie(dice, die), explodeOn, meta);

  public static function diceDropLow<T>(dice: Array<Die<T>>, drop: Int, meta: T): DiceExpression<T>
    return RollAndDropLow(DiceList(dice), drop, meta);

  public static function diceKeepHigh<T>(dice: Array<Die<T>>, keep: Int, meta: T): DiceExpression<T>
    return RollAndKeepHigh(DiceList(dice), keep, meta);

  public static function diceExplosive<T>(dice: Array<Die<T>>, explodeOn: Int, meta: T): DiceExpression<T>
    return RollAndExplode(DiceList(dice), explodeOn, meta);

  public static function add<T>(a: DiceExpression<T>, b: DiceExpression<T>, meta: T): DiceExpression<T>
    return BinaryOp(Sum, a, b, meta);

  public static function subtract<T>(a: DiceExpression<T>, b: DiceExpression<T>, meta: T): DiceExpression<T>
    return BinaryOp(Difference, a, b, meta);

  public static function literal<T>(value: Int, meta: T): DiceExpression<T>
    return Literal(value, meta);

  public static function d2<T>(meta: T): Die<T>
    return new Die(2, meta);
  public static function d4<T>(meta: T): Die<T>
    return new Die(4, meta);
  public static function d6<T>(meta: T): Die<T>
    return new Die(6, meta);
  public static function d8<T>(meta: T): Die<T>
    return new Die(8, meta);
  public static function d10<T>(meta: T): Die<T>
    return new Die(10, meta);
  public static function d12<T>(meta: T): Die<T>
    return new Die(12, meta);
  public static function d20<T>(meta: T): Die<T>
    return new Die(20, meta);
  public static function d100<T>(meta: T): Die<T>
    return new Die(100, meta);
}