package dapi;

using thx.Functions;
using thx.Arrays;

class DiceExpressionExtensions {
  public static function toString<T>(expr: DiceExpression<T>) return switch expr {
    case RollOne(die):
      die.toString();
    case RollMany(dice, _):
      diceToString(dice);
    case RollAndDropLow(dice, drop, _):
      diceToString(dice) + 'd$drop';
    case RollAndKeepHigh(dice, keep, _):
      diceToString(dice) + 'k$keep';
    case RollAndExplode(dice, explodeOn, _):
      diceToString(dice) + 'x$explodeOn';
    case BinaryOp(Sum, a, b, _):
      toString(a) + " + " + toString(b);
    case BinaryOp(Difference, a, b, _):
      toString(a) + " - " + toString(b);
    case Literal(value, _):
      '$value';
  }

  public static function diceToString<T>(dice: Array<Die<T>>): String {
    var sides = dice.map.fn(_.sides).distinct();
    return if(sides.length == 1) // all dice have the same number of sides
      dice.length + dice[0].toString();
    else
      '{' + dice.map.fn(_.toString()).join(" + ") + '}';
  }
}