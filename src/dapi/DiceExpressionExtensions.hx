package dapi;

using thx.Functions;
import dapi.DiceExpression;

class DiceExpressionExtensions {
  public static function toString<T>(expr: DiceExpression<T>) return switch expr {
    case RollOne(die):
      die.toString();
    case RollGroup(dice, extractor, _):
      diceToString(dice, extractor);
    case BinaryOp(Sum, a, b, _):
      toString(a) + " + " + toString(b);
    case BinaryOp(Difference, a, b, _):
      toString(a) + " - " + toString(b);
    case Literal(value, _):
      '$value';
  }

  public static function diceToString<T>(group: DiceGroup<T>, extractor: GroupExtractor)
    return (switch group {
      case DiceList(dice):
         '{' + dice.map.fn(_.toString()).join(",") + '}';
      case RepeatDie(time, die):
        '${time}${die.toString()}';
    }) + (switch extractor {
      case Sum: "";
      case DropLow(drop): 'd$drop';
      case KeepHigh(keep): 'k$keep';
      case ExplodeOn(explodeOn): 'e$explodeOn';
    });
}