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
      expressionsToString(exprs, extractor);
    case BinaryOp(op, a, b, _):
      toString(a) + " " + (switch op {
        case Sum: "+";
        case Difference: "-";
        case Multiplication: "*";
        case Division: "/";
      }) + " " + toString(b);
    case UnaryOp(Negate, a, _):
      "-" + toString(a);
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
        var s = dice.map.fn(_.toString()).join(",");
         '{' + s + '}';
      case RepeatDie(time, die):
        '${time}${die.toString()}';
    }) + (switch extractor {
      case ExplodeOn(explodeOn): 'e$explodeOn';
    });

  public static function expressionsToString<T>(exprs: Array<DiceExpression<T>>, extractor: ExpressionExtractor)
    return 
      (exprs.length == 1 && !needsBraces(exprs[0]) ?
        exprs.map(toString).join(",") :
        '{' + exprs.map(toString).join(",") + '}') +
        expressionExtractorToString(extractor);

  public static function expressionExtractorToString(extractor) return switch extractor {
    case Sum: "";
    case Average: " average";
    case Min: " min";
    case Max: " max";
    case DropLow(drop): 'd$drop';
    case KeepHigh(keep): 'k$keep';
  };

  public static function needsBraces(expr) return switch expr {
    case BinaryOp(_, _, _, _): true;
    case Roll(_): false;
    case RollBag(_): false;
    case RollExpressions(_): false;
    case UnaryOp(_): false;
  }

    public static function extractMeta<T>(expr: DiceExpression<T>): T {
    return switch expr {
      case Roll(One(die)):
        die.meta;
      case RollBag(_, _, meta) |
           RollExpressions(_, _, meta) |
           BinaryOp(_, _, _, meta) |
           UnaryOp(_, _, meta) |
           Roll(Bag(_, meta)) |
           Roll(Repeat(_, _, meta)) |
           Roll(Literal(_, meta)):
        meta;
    };
  }
}