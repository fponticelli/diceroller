package dr;

using thx.Functions;
import dr.DiceExpression;

class DiceExpressionExtensions {
  public static function toString<T>(expr: DiceExpression<T>) return switch expr {
    case RollOne(die):
      die.toString();
    case RollBag(dice, extractor, _):
      diceBagToString(dice, extractor);
    case RollExpressions(exprs, extractor, _):
      expressionBagToString(exprs, extractor);
    case BinaryOp(Sum, a, b, _):
      toString(a) + " + " + toString(b);
    case BinaryOp(Difference, a, b, _):
      toString(a) + " - " + toString(b);
    case Literal(value, _):
      '$value';
  }

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

  public static function expressionBagToString<T>(group: ExpressionBag<T>, extractor: ExpressionExtractor)
    return (switch group {
      case ExpressionSet(exprs):
         '{' + exprs.map(toString).join(",") + '}';
      case RepeatDie(time, die):
        '${time}${die.toString()}';
    }) + (switch extractor {
      case Sum: "";
      case DropLow(drop): 'd$drop';
      case KeepHigh(keep): 'k$keep';
    });
}