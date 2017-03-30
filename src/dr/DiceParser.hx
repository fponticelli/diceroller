package dr;

import dr.DiceExpression;
import parsihax.Parser.*;
import parsihax.ParseObject;
import parsihax.ParseResult;
using parsihax.Parser;
using thx.Arrays;
using thx.Functions;
using thx.Strings;
import thx.Validation;
import haxe.ds.Option;
using thx.Options;

class DiceParser {
  public static function parse(s: String): Validation<DiceParseError, DiceExpression> {
    return switch grammar
      .apply(s) {
        case { status: true, value: value }:
          Validation.success(value);
        case v:
          var err = DiceParseError.fromResult(v, s);
          Validation.failure(err);
      };
  }
  public static function unsafeParse(s: String) return switch parse(s) {
    case Left(e): throw e;
    case Right(v): v;
  }

  public static function normalize(s: String)
    return DiceExpressionExtensions.toString(unsafeParse(s));

  static var PLUS = "+".string();
  static var MINUS = "-".string();
  static var positive = ~/[+]?([1-9][0-9]*)/.regexp(1).map(Std.parseInt);
  static var negative = ~/[-]([0-9]*[1-9])/.regexp().map(Std.parseInt);
  static var whole = positive | negative;
  static var D = "d".string() | "D".string();

  static var OPEN_SET_BRACKET = "(".string();
  static var CLOSE_SET_BRACKET = ")".string();
  static var COMMA = ",".string();
  static var PERCENT = "%".string();
  static var WS = ~/[\s_]+/m.regexp();
  static var OWS = WS | "".string();

  static var MULTIPLICATION = ~/[*⋅×x]/.regexp() / "×";
  static var DIVISION = "/".string() | "÷".string() | ":".string();

  static var lowOrHigh = ("lowest".string() | "low".string()).result(Low) | ("highest".string() | "high".string()).result(High);
  static function dirValue(prefix: ParseObject<String>, alt: LowHigh): ParseObject<{ dir: LowHigh, value: Int}> {
    return prefix + OWS + [
        lowOrHigh.flatMap(function(lh: LowHigh) {
          return OWS + positive.map(function(value) {
            return { dir: lh, value: value };
          });
        }),
        positive.map(function(value) {
          return { dir: alt, value: value };
        })
      ].alt();
  }

  static var moreLess = "more".string().result(MoreLess.More) | "less".string().result(MoreLess.Less);
  static var orMoreLess = OWS + "or".string() + OWS + moreLess / "or (more|less)";
  static var on = "on".string() + WS + positive;
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

  static function diceFunctorConst(p: String, f): ParseObject<DiceFunctor> {
    return [
      p.string() + OWS + functorTimes.flatMap(function(times) {
        return OWS + range.map(function(range) {
          return f(times, range);
        });
      })
    ].alt();
  }

  static var diceFunctor: ParseObject<DiceFunctor> = function() {
    return [
      "e".string() + OWS + positive.map.fn(Explode(Always, ValueOrMore(_))),
      "r".string() + OWS + positive.map.fn(Reroll(Always, ValueOrLess(_))),
      diceFunctorConst("explode", Explode),
      diceFunctorConst("reroll", Reroll)
    ].alt();
  }.lazy();

  static var SUM = "sum".string();
  static var AVERAGE = "average".string().or("avg".string());
  static var MEDIAN = "median".string().or("mdn".string());
  static var MIN = "minimum".string().or("min".string());
  static var MAX = "maximum".string().or("max".string());

  static var times = [
    "once".string().result(1),
    "twice".string().result(2),
    "thrice".string().result(3),
    positive.skip(OWS + "times".string())
  ].alt();

  static var functorTimes = [
    times.map(UpTo),
    OWS + "always".string().result(Always),
    "".string().result(Always)
  ].alt();

  static var DEFAULT_DIE_SIDES = 6;
  static var die = [
      (D + PERCENT).result(100),
      (D + positive),
      D.result(DEFAULT_DIE_SIDES)
    ].alt() / "one die";

  static var negate: ParseObject<DiceExpression> = function() {
    return MINUS + termExpression.map(function(expr) {
      return UnaryOp(Negate, expr);
    });
  }.lazy() / "negate";

  static var unary = [negate].alt();

  static var binOpSymbol = [
      PLUS.result(DiceBinOp.Sum),
      MINUS.result(DiceBinOp.Difference),
      MULTIPLICATION.result(DiceBinOp.Multiplication),
      DIVISION.result(DiceBinOp.Division)
    ].alt();

  static var opRight = OWS + binOpSymbol.flatMap(function(o: DiceBinOp) {
      return OWS +
        termExpression.map(function(b: DiceExpression) {
          return { op: o, right: b };
        });
    });

  static var binop: ParseObject<DiceExpression> =
    function() {
      return termExpression.flatMap(
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

  static var dieExpression = "1".string() + die.map(Die) | die.map(Die) / "die";
  static var literalExpression = whole.map(Literal) / "literal";

  static function diceReduce(reduceable: ParseObject<DiceReduceable>) {
    return reduceable
      .flatMap(function(red) {
        return OWS + [
          SUM.result(Sum),
          AVERAGE.result(Average),
          MEDIAN.result(Median),
          MIN.result(Min),
          MAX.result(Max)
        ].alt().map(function(reducer) {
          return DiceReduce(red, reducer);
        });
      }) |
      reduceable.map.fn(DiceReduce(_, Sum));
  }

  static function commaSeparated<T>(element: ParseObject<T>): ParseObject<Array<T>> {
    return OPEN_SET_BRACKET + OWS +
      element.sepBy(OWS + COMMA + OWS)
        .skip(OWS + CLOSE_SET_BRACKET);
  }

  static var diceExpressions = function(): ParseObject<DiceReduceable> {
    return [
      positive.flatMap(function(rolls) {
        return die.map(function(sides) {
          return DiceExpressions([for(i in 0...rolls) Die(sides)]);
        });
      }),
      commaSeparated(expression).map(DiceExpressions)
    ].alt();
  }.lazy();

  static var diceFilterable = function(): ParseObject<DiceReduceable> {
    return [
      positive.flatMap(function(rolls) {
        return die.map(function(sides) {
          return DiceArray([for (i in 0...rolls) sides]);
        });
      }),
      commaSeparated(die).map(function(dice) {
        return DiceArray(dice);
      }),
      commaSeparated(expression).map(DiceFilterable.DiceExpressions)
    ].alt().flatMap(function(filterable) {
      return OWS + [
        "d".string() + OWS + positive.map.fn(Drop(Low, _)),
        dirValue("drop".string(), LowHigh.Low).map.fn(Drop(_.dir, _.value)),
        "k".string() + OWS + positive.map.fn(Keep(High, _)),
        dirValue("keep".string(), LowHigh.High).map.fn(Keep(_.dir, _.value))
      ].alt().map(function(dk) {
        return DiceListWithFilter(filterable, dk);
      });
    });
  }.lazy();

  static var diceMapeable = function(): ParseObject<DiceReduceable> {
    return [
      positive.flatMap(function(rolls) {
        return die.map(function(sides) {
          return [for(i in 0...rolls) sides];
        });
      }),
      commaSeparated(die),
      "1".string() + die.map.fn([_]),
      die.map.fn([_]),
    ].alt().flatMap(function(arr) {
      return OWS + diceFunctor.map(function(functor) {
        return DiceListWithMap(arr, functor);
      });
    });
  }.lazy();

  static var termExpression: ParseObject<DiceExpression> = function() {
    return [
      diceReduce(diceMapeable),
      diceReduce(diceFilterable),
      diceReduce(diceExpressions),
      dieExpression,
      literalExpression,
      unary
    ].alt();
  }.lazy();

  static var expression: ParseObject<DiceExpression> = function() {
    return [
      binop,
      termExpression
    ].alt();
  }.lazy() / "expression";

  static var grammar =
    OWS + expression.skip(OWS).skip(eof());
}

class DiceParseError {
  public var expected(default, null): Array<String>;
  public var furthest(default, null): Int;
  public var input(default, null): String;
  public function new(expected: Array<String>, furthest: Int, input: String) {
    this.expected = expected;
    this.furthest = furthest;
    this.input = input;
  }

  public static function fromResult<T>(r: ParseResult<T>, s: String) {
    var expected = r.expected.map(expectedToString).distinct();
    return new DiceParseError(expected, r.furthest, s);
  }

  static function expectedToString(e: Dynamic) {
    var s = Std.string(e);
    if(s.startsWith("{\n	r : ")) {
      s = s.trimCharsLeft("{ \n\tr:").trimCharsRight("\n\t }");
    }
    return s;
  }

  public function positionToString(): Option<String> {
    return if(furthest >= input.length) {
      None;
    } else {
      Some(input.substring(furthest));
    };
  }

  public function toString() {
    var got = positionToString().map.fn("…" + _.ellipsis(20)).getOrElse("end of file");
    return 'expected ${expected.join(", ")} but got $got';
  }
}

enum MoreLess {
  More;
  Less;
}
