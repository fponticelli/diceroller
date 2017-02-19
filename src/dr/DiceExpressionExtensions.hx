package dr;

using thx.Functions;
import dr.DiceExpression;

class DiceExpressionExtensions {
  public static function toString<T>(expr: DiceExpression<T>) return switch expr {
    case Roll(roll):
      rollToString(roll);
    case RollBag(dice, extractor, _):
      diceBagToString(dice, extractor);
    case RollExpressions(exprs, extractor, _):
      expressionBagToString(exprs, extractor);
    case BinaryOp(Sum, a, b, _):
      toString(a) + " + " + toString(b);
    case BinaryOp(Difference, a, b, _):
      toString(a) + " - " + toString(b);
  }

  public static function rollToString<T>(roll: BasicRoll<T>)
    return switch roll {
      case Literal(value, _):
        '$value';
      case One(die):
        die.toString();
      case Bag(list, _):
        '{' + list.map(rollToString).join(",") + '}';
      case Repeat(time, die, _):
        '${time}${die.toString()}';
    };

  public static function diceBagToString<T>(group: DiceBag<T>, extractor: BagExtractor)
    return (switch group {
      case DiceSet(dice):
         '{' + dice.map.fn(_.toString()).join(",") + '}';
      case RepeatDie(time, die):
        '${time}${die.toString()}';
    }) + (switch extractor {
      case Sum: "";
      case DropLow(drop): 'd$drop';
      case KeepHigh(keep): 'k$keep';
      case ExplodeOn(explodeOn): 'e$explodeOn';
    });

  public static function expressionBagToString<T>(exprs: Array<DiceExpression<T>>, extractor: ExpressionExtractor)
    return '{' + exprs.map(toString).join(",") + '}' +
    (switch extractor {
      case Sum: "";
      case DropLow(drop): 'd$drop';
      case KeepHigh(keep): 'k$keep';
    });
}