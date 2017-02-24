package dr;

import parsihax.Parser.*;
import parsihax.ParseObject;
using parsihax.Parser;
using thx.Arrays;
using thx.Functions;
import thx.Validation;
import dr.DiceExpression;

class DiceParser {
  public static function parse(s: String): Validation<String, DiceExpression> {
    return switch grammar.apply(s) {
      case { status: true, value: value }:
        Validation.success(value);
      case v:
        var msg = parsihax.ParseUtil.formatError(v, s);
        Validation.failure(msg);
    };
  }

  public static function unsafeParse(s: String) return switch parse(s) {
    case Left(e): throw e;
    case Right(v): v;
  }

  static var PLUS = "+".string() / "plus";
  static var MINUS = "-".string() / "minus";
  static var positive = ~/[+]?([1-9][0-9]*)/.regexp(1).map(Std.parseInt) / "positive number";
  static var negative = ~/[-]([0-9]*[1-9])/.regexp().map(Std.parseInt) / "negative number";
  static var whole = positive | negative / "whole number";
  static var D = "d".string() | "D".string() / "die symbol";

  static var OPEN_SET_BRACKET = "{".string() / "open set";
  static var OPEN_PAREN = "(".string() / "open parenthesis";
  static var CLOSE_SET_BRACKET = "}".string() / "close set";
  static var CLOSE_PAREN = ")".string() / "close parenthesis";
  static var COMMA = ",".string() / "comma";
  static var PERCENT = "%".string() / "percent";
  static var WS = ~/\s+/m.regexp() / "white space";
  static var OWS = WS | "".string() / "optional white space";
  static function SKIP_WS(parser)
    return skip(parser, WS);
  static function SKIP_OWS(parser)
    return skip(parser, OWS);

  static var MULTIPLICATION = ~/[*⋅×x]/.regexp() / "multiplication symbol";
  static var DIVISION = "/".string() | "÷".string() | ":".string() / "division symbol";

  static var keepOrDrop = "keep".string().result(Keep) | "drop".string().result(Drop);
  static var lowOrHigh = ("lowest".string() | "low".string()).result(Low) | ("highest".string() | "high".string()).result(High);
  static var explodeOrReroll = "explode".string().result(Explode) | "reroll".string().result(Reroll);
  static var moreLess = "more".string().result(MoreLess.More) | "less".string().result(MoreLess.Less);
  static var orMoreLess = SKIP_WS("or".string()) + moreLess / "or (more|less)";
  static var on = "on".string() + WS + positive;
  static var to = "to".string() + WS + positive;
  static var range = [
    on.flatMap(function(min) {
      return OWS + positive.map(function(max) {
        return Between(min, max);
      });
    }),
    on.flatMap(function(value) {
      return OWS + orMoreLess.map(function(ml) return switch ml {
        case More: ValueOrMore(value);
        case Less: ValueOrLess(value);
      });
    }),
    on.map(Exact)
  ].alt();

  static var SUM = "sum".string() / "sum";
  static var AVERAGE = "average".string().or("avg".string()) / "average";
  static var MIN = "minimum".string().or("min".string()) / "minimum";
  static var MAX = "maximum".string().or("max".string()) / "maximum";

  static var times = [
    "once".string().result(1),
    "twice".string().result(2),
    "thrice".string().result(3),
    SKIP_OWS(positive).skip("times".string())
  ].alt() / "times";


  static var literal = positive.map.fn(Literal(_)) / "literal";
  // static var literal = basicLiteral.map(Roll) / "literal";

  static var DEFAULT_DIE_SIDES = 6;
  static var die = [
      (D + PERCENT).result(100),
      (D + positive),
      D.result(DEFAULT_DIE_SIDES)
    ].alt() / "one die";

  static var basicDice = [
    positive.flatMap(function(rolls) {
      return die.map(function(die) {
        return if(rolls == 1) {
          Die(die);
        } else {
          Dice(rolls, die);
        }
      });
    }),
    die.map.fn(Die(_))
  ].alt() / "basic dice";
  // static var dice = basicDice.map(Roll) / "dice";

  static var basicDiceSetElement = [
    basicDice,
    literal
  ].alt() / "dice set element";

  static var basicDiceArray: ParseObject<Array<DiceExpression>> = function() {
    return [
      OPEN_SET_BRACKET + OWS + [
        basicDiceSetElement,
        diceSet
      ].alt().sepBy(OWS + COMMA + OWS).skip(OWS + CLOSE_SET_BRACKET),
      basicDice.map(function(v) return [v])
    ].alt();
  }.lazy() / "dice set";

  // static var diceSetArray: ParseObject<Array<DiceExpression>> = function() {
  //   return basicDiceArray.map(RollExpressions.bind(_, Sum));
  // }.lazy() / "dice set";

  static var diceSet = basicDiceArray.map(DiceReducer.bind(_, Sum)) / "dice set";

  static var diceMap =  [
    OPEN_SET_BRACKET + OWS +
      die.sepBy(OWS + COMMA + OWS)
          .skip(OWS + CLOSE_SET_BRACKET)
          // .map(DiceArray)
          ,
    positive.flatMap(function(rolls) {
      return die.map(function(sides) {
        return [for(i in 0...rolls) sides];
      }
        // RepeatDie.bind(rolls, _)
      );
    }),
  ].alt();

  static var explodeOrRerollBag = OWS + diceMap.flatMap(function(db) {
    return OWS + explodeOrReroll.flatMap(function(er) {
      return OWS + [
        times.flatMap(function(t) {
          var upTo = UpTo(t);
          return WS + range.map(function(on) {
            return DiceMap(db, switch er {
              case Explode:
                Explode(upTo, on);
              case Reroll:
                Reroll(upTo, on);
            });
          });
        }),
        range.map(function(ml) {
          return DiceMap(db, switch er {
            case Explode:
              Explode(Always, Exact(1));
            case Reroll:
              Reroll(Always, Exact(1));
          });
        })
      ].alt();
    });
  });

  static var diceMapOp = [
    explodeOrRerollBag
  ].alt();

  static var basicExpressionSet: ParseObject<Array<DiceExpression>> = function() {
    return OPEN_SET_BRACKET + OWS +
      expression
        .sepBy(OWS + ",".string() + OWS)
        .skip(OWS + CLOSE_SET_BRACKET);
  }.lazy() / "expression set";

  static var diceOrSet = [
    diceSet.map(function(v) {
      return switch v {
        case DiceReducer(list, _):
          list;
        case _:
          [v];
      };
    }),
    basicExpressionSet
  ].alt();

  static var expressionSetImplicit: ParseObject<DiceExpression> =
    diceOrSet.map.fn(DiceReducer(_, Sum)) / "implicit sum";
  static var expressionSetSum: ParseObject<DiceExpression> =
    diceOrSet.skip(OWS + SUM).map.fn(DiceReducer(_, Sum)) / "sum";
  static var expressionSetAverage: ParseObject<DiceExpression> =
    diceOrSet.skip(OWS + AVERAGE).map.fn(DiceReducer(_, Average)) / "average";
  static var expressionSetMin: ParseObject<DiceExpression> =
    diceOrSet.skip(OWS + MIN).map.fn(DiceReducer(_, Min)) / "minimum";
  static var expressionSetMax: ParseObject<DiceExpression> =
    diceOrSet.skip(OWS + MAX).map.fn(DiceReducer(_, Max)) / "maximum";
  static var expressionSetDropOrKeep: ParseObject<DiceExpression> =
    diceOrSet.skip(WS).flatMap(function(expr) {
      return keepOrDrop.flatMap(function(kd) {
        return WS + (lowOrHigh.flatMap(function(lh) {
          return WS + positive.map(function(value) {
            return switch kd {
              case Drop:
                DiceReducer(expr, Drop(lh, value));
              case Keep:
                DiceReducer(expr, Keep(lh, value));
            };
          });
        }) |
          positive.map(function(value) {
            return switch kd {
              case Drop:
                DiceReducer(expr, Drop(Low, value));
              case Keep:
                DiceReducer(expr, Keep(High, value));
            };
          })
        );
      });
    }) / "keep or drop";

  static var expressionSetOp = [
    expressionSetDropOrKeep,
    expressionSetAverage,
    expressionSetMin,
    expressionSetMax,
    expressionSetSum,
    expressionSetImplicit
  ].alt();

  static var negate: ParseObject<DiceExpression> = function() {
    return MINUS + inlineExpression.map(function(expr) {
      return UnaryOp(Negate, expr);
    });
  }.lazy() / "negate";

  static var binOpSymbol = [
      PLUS.result(DiceBinOp.Sum),
      MINUS.result(DiceBinOp.Difference),
      MULTIPLICATION.result(DiceBinOp.Multiplication),
      DIVISION.result(DiceBinOp.Division)
    ].alt();

  static var opRight = OWS + binOpSymbol.flatMap(function(o: DiceBinOp) {
      return OWS +
        inlineExpression.map(function(b: DiceExpression) {
          return { op: o, right: b };
        });
    });

  static var binop: ParseObject<DiceExpression> =
    function() {
      return inlineExpression.flatMap(
        function(left: DiceExpression) {
          return opRight.times(1, 1000).map(function(a) {
            return a.reduce(function(left, item) {
              return switch item.op {
                case Sum | Difference:
                  return BinaryOp(item.op, left, item.right);
                case Multiplication | Division: // this seems too complicated but it works for now
                  return switch left {
                    case BinaryOp(o, l, r):
                      BinaryOp(o, l, BinaryOp(item.op, r, item.right));
                    case other:
                      BinaryOp(item.op, left, item.right);
                  };
              };
            }, left);
          });
        }
      );
    }.lazy();

  static var expressionOperations = [
    binop
  ].alt();

  static var inlineExpression: ParseObject<DiceExpression> = function() {
    return [
      diceMapOp,
      expressionSetOp,
      diceSet,
      literal,
      negate
    ].alt();
  }.lazy() / "inline expression";

  static var expression: ParseObject<DiceExpression> = function() {
    return [
      expressionOperations,
      inlineExpression
    ].alt();
  }.lazy() / "expression";

  static var grammar =
    OWS + expression.skip(OWS).skip(eof());
}

enum DropKeep {
  Drop;
  Keep;
}

enum ExplodeReroll {
  Explode;
  Reroll;
}

enum MoreLess {
  More;
  Less;
}