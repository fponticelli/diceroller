package dr;

import dr.DiceExpression;
using thx.Arrays;
using thx.Strings;
using thx.Functions;
using thx.Nel;
import haxe.ds.Option;

class DiceExpressionExtensions {
  public static function toString(expr: DiceExpression) return switch expr {
    case Literal(value):
      '$value';
    case Die(sides):
      diceToString(1, sides);
    case DiceReduce(DiceExpressions(exprs), reducer):
      expressionsToString(exprs) + expressionExtractorToString(reducer);
    case DiceReduce(DiceListWithFilter(DiceArray(dice), filter), reducer):
      sidesToString(dice) + diceFilterToString(filter) + expressionExtractorToString(reducer);
    case DiceReduce(DiceListWithFilter(DiceExpressions(exprs), filter), reducer):
      expressionsToString(exprs) + diceFilterToString(filter) + expressionExtractorToString(reducer);
    case DiceReduce(DiceListWithMap(dice, functor), reducer):
    diceBagToString(dice, functor) + expressionExtractorToString(reducer);
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

  public static function diceToString(times: Int, sides: Int) {
    return switch [times, sides] {
      case [1, 100]: "d%";
      case [1, _]:   'd$sides';
      case [_, 100]: '${times}d%';
      case [_, _]:   '${times}d$sides';
    }
  }

  public static function diceBagToString<T>(dice: Array<Sides>, functor: DiceFunctor) {
    return sidesToString(dice) +
    (switch functor {
      case Explode(times, range):
        [" explode"].concat([timesToString(times)]).concat([rangeToString(range)]).filter(Strings.hasContent).join(" ");
      case Reroll(times, range):
        [" reroll"].concat([timesToString(times)]).concat([rangeToString(range)]).filter(Strings.hasContent).join(" ");
    });
  }

  public static function sidesToString(dice: Array<Sides>) {
    return if(dice.distinct().length == 1) {
      diceToString(dice.length, dice[0]);
    } else {
      var s = dice.map(diceToString.bind(1, _)).join(",");
      '(' + s + ')';
    }
  }

  public static function timesToString(times: Times) {
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

  public static function expressionsToString<T>(exprs: Array<DiceExpression>) {
    if(allOneDieSameSides(exprs)) {
      return (exprs.length > 1 ? '${exprs.length}' : "") + toString(exprs[0]);
    } else {
      return
        (exprs.length == 1 && !needsBraces(exprs[0]) ?
          exprs.map(toString).join(",") :
          '(' + exprs.map(toString).join(",") + ')');
    }
  }

  public static function allOneDieSameSides(exprs: Array<DiceExpression>) {
    var sides = [];
    for(expr in exprs) {
      switch expr {
        case Die(s):
          sides.push(s);
        case _:
          return false;
      }
    }
    return sides.distinct().length == 1;
  }

  public static function expressionExtractorToString(functor) return switch functor {
    case Sum: "";
    case Average: " average";
    case Median: " median";
    case Min: " min";
    case Max: " max";
  };

  public static function diceFilterToString(filter) return switch filter {
    case Drop(Low, drop):  ' drop $drop';
    case Drop(High, drop): ' drop highest $drop';
    case Keep(High, drop): ' keep $drop';
    case Keep(Low, drop):  ' keep lowest $drop';
  };

  public static function needsBraces(expr) return switch expr {
    case BinaryOp(_, _, _): true;
    case Literal(_): false;
    case Die(_): false;
    case DiceReduce(_): false;
    case UnaryOp(_): false;
  }

  static function validateExpr(expr: DiceExpression): Array<ValidationMessage> {
    return switch expr {
      case Die(sides) if(sides <= 0):
        [InsufficientSides(sides)];
      case DiceReduce(reduceable, reducer):
        validateDiceReduceable(reduceable);
      case BinaryOp(op, a, b):
        validateExpr(a).concat(validateExpr(b));
      case UnaryOp(op, a):
        validateExpr(a);
      case Literal(_) | Die(_):
        [];
    };
  }

  static function validateDiceReduceable(dr: DiceReduceable) {
    return switch dr {
      case DiceExpressions(exprs) if(exprs.length == 0):
        [EmptySet];
      case DiceExpressions(exprs):
        exprs.map(validateExpr).flatten();
      case DiceListWithFilter(list, filter):
        var acc = [],
            len = switch list {
              case DiceArray(dice): dice.length;
              case DiceExpressions(exprs): exprs.length;
            };
        switch filter {
          case Drop(_, value) | Keep(_, value) if(value < 1):
            acc.push(DropOrKeepShouldBePositive);
          case Drop(_, value) if(value >= len):
            acc.push(TooManyDrops(len, value));
          case Keep(_, value) if(value > len):
            acc.push(TooManyKeeps(len, value));
          case _:
        }
        acc;
      case DiceListWithMap(dice, functor):
        var acc = dice.reduce(function(acc: Array<ValidationMessage>, sides: Int) {
          if(sides > 0) return acc;
          return acc.concat([InsufficientSides(sides)]);
        }, []);
        acc.concat(dice.map.fn(checkFunctor(_, functor)).flatten());
    };
  }

  static function alwaysInRange(sides: Int, range: Range) {
    for(i in 1...sides+1)
      if(!Roller.matchRange(i, range)) return false;
    return true;
  }

  static function checkFunctor(sides: Int, df: DiceFunctor)
    return switch df {
      case Explode(_, range) | Reroll(_, range) if(alwaysInRange(sides, range)):
        [InfiniteReroll(sides, range)];
      case _:
        [];
    };

  public static function validate(expr: DiceExpression): Option<Nel<ValidationMessage>>
    return Nel.fromArray(validateExpr(expr));
}

enum ValidationMessage {
  InsufficientSides(sides: Int);
  EmptySet;
  InfiniteReroll(sides: Int, range: Range);
  TooManyDrops(available: Int, toDrop: Int);
  TooManyKeeps(available: Int, toKeep: Int);
  DropOrKeepShouldBePositive;
}
