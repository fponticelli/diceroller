package dapi;

using thx.Functions;
using thx.Arrays;
import dapi.DiceExpression;

class DiceExpressionExtensions {
  public static function toString<T>(expr: DiceExpression<T>) return switch expr {
    case RollOne(die):
      die.toString();
    case RollGroup(dice, _):
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

  public static function diceToString<T>(group: DiceGroup<T>)
    return switch group {
      case DiceList(dice):
         '{' + dice.map.fn(_.toString()).join(",") + '}';
      case RepeatDie(time, die):
        '${time}${die.toString()}';
    };
}