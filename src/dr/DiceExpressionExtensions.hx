package dr;

using thx.Strings;
import dr.DiceExpression;

class DiceExpressionExtensions {
  public static function toString(expr: DiceExpression) return switch expr {
    case Roll(roll):
      rollToString(roll);
    case RollBag(dice, extractor):
      diceBagToString(dice, extractor);
    case RollExpressions(exprs, extractor):
      expressionsToString(exprs, extractor);
    case BinaryOp(op, a, b):
      toString(a) + " " + (switch op {
        case Sum: "+";
        case Difference: "-";
        case Multiplication: "*";
        case Division: "/";
      }) + " " + toString(b);
    case UnaryOp(Negate, a):
      "-" + toString(a);
  }

  public static function rollToString(roll: BasicRoll)
    return switch roll {
      case Literal(value):
        '$value';
      case One(sides):
        diceToString(1, sides);
      case Bag(list):
        '{' + list.map(rollToString).join(",") + '}';
      case Repeat(times, sides):
        diceToString(times, sides);
    };

  public static function diceToString(times: Int, sides: Int) {
    return switch [times, sides] {
      case [1, 100]: "d%";
      case [1, _]:   'd$sides';
      case [_, 100]: '${times}d%';
      case [_, _]:   '${times}d$sides';
    }
  }

  public static function diceBagToString<T>(group: DiceBag, extractor: BagExtractor)
    return (switch group {
      case DiceSet(dice):
        var s = dice.map(diceToString.bind(1, _)).join(",");
         '{' + s + '}';
      case RepeatDie(times, sides):
        diceToString(times, sides);
    }) + (switch extractor {
      case Explode(times, range):
        [' explode'].concat([timesToString(times)]).concat([rangeToString(range)]).filter(Strings.hasContent).join(" ");
      case Reroll(times, range):
        [' reroll'].concat([timesToString(times)]).concat([rangeToString(range)]).filter(Strings.hasContent).join(" ");
    });

  public static function timesToString(times: Times) {
    // TODO
    return switch times {
      case Always: "";
      case UpTo(1): "once";
      case UpTo(2): "twice";
      case UpTo(n): '$n times';
    };
  }

  public static function rangeToString(range: Range) {
    return switch range {
      case Exact(v): 'on $v';
      case Between(a, b): '$a...$b';
      case Composite(arr): '(${arr.map(rangeToString).join(",")})';
      case ValueOrLess(v): 'on $v or less';
      case ValueOrMore(v): 'on $v or more';
    };
  }

  public static function expressionsToString<T>(exprs: Array<DiceExpression>, extractor: ExpressionExtractor)
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
    case Drop(Low, drop):  ' drop $drop';
    case Drop(High, drop): ' drop highest $drop';
    case Keep(High, drop): ' keep $drop';
    case Keep(Low, drop):  ' keep lowest $drop';
  };

  public static function needsBraces(expr) return switch expr {
    case BinaryOp(_, _, _): true;
    case Roll(_): false;
    case RollBag(_): false;
    case RollExpressions(_): false;
    case UnaryOp(_): false;
  }
}

class DiceResultExtensions {
  public static function getResult<T>(expr: DiceResult<T>): T {
    return switch expr {
      case Roll(One(die)):
        die.result;
      case RollBag(_, _, result) |
           RollExpressions(_, _, result) |
           BinaryOp(_, _, _, result) |
           UnaryOp(_, _, result) |
          //  Roll(Bag(_, result)) |
           Roll(Literal(_, result)):
        result;
    };
  }
}