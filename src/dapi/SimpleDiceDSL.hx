package dapi;

import dapi.DiceExpression;
import thx.Unit;

class SimpleDiceDSL {
  public static function dice(dice: Array<Die<Unit>>): DiceExpression<Unit>
    return DiceDSL.dice(dice, unit);

  public static function die(sides: Int): DiceExpression<Unit>
    return DiceDSL.die(sides, unit);

  public static function dropLow(dice: Array<Die<Unit>>, drop: Int): DiceExpression<Unit>
    return DiceDSL.dropLow(dice, drop, unit);

  public static function keepHigh(dice: Array<Die<Unit>>, keep: Int): DiceExpression<Unit>
    return DiceDSL.keepHigh(dice, keep, unit);

  public static function explosive(dice: Array<Die<Unit>>, explodeOn: Int): DiceExpression<Unit>
    return DiceDSL.explosive(dice, explodeOn, unit);

  public static function add(a: DiceExpression<Unit>, b: DiceExpression<Unit>): DiceExpression<Unit>
    return DiceDSL.add(a, b, unit);

  public static function subtract(a: DiceExpression<Unit>, b: DiceExpression<Unit>): DiceExpression<Unit>
    return DiceDSL.subtract(a, b, unit);

  public static function literal(value: Int): DiceExpression<Unit>
    return DiceDSL.literal(value, unit);

  public static var d2(default, null) = DiceDSL.d2(unit);
  public static var d4(default, null) = DiceDSL.d4(unit);
  public static var d6(default, null) = DiceDSL.d6(unit);
  public static var d8(default, null) = DiceDSL.d8(unit);
  public static var d10(default, null) = DiceDSL.d10(unit);
  public static var d12(default, null) = DiceDSL.d12(unit);
  public static var d20(default, null) = DiceDSL.d20(unit);
  public static var d100(default, null) = DiceDSL.d100(unit);
}