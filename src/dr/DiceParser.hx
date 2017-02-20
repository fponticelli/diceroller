package dr;

import parsihax.Parser.*;
import parsihax.ParseObject;
using parsihax.Parser;
using thx.Arrays;
using thx.Functions;
import thx.Unit;
import thx.Validation;
import dr.DiceExpression;

class DiceParser {
  public static function parse(s: String): Validation<String, DiceExpression<Unit>> {
    return switch grammar.apply(s) {
      case { status: true, value: value }:
        trace(value);
        Validation.success(value);
      case v:
        var msg = parsihax.ParseUtil.formatError(v, s);
        Validation.failure(msg);
    };
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

  static var KEEP_OR_DROP = "keep".string() | "drop".string();
  static var LOW_HIGH = "lowest".string() | "low".string() | "highest".string() | "high".string();
  static var MORE_LESS = "more".string() | "less".string();
  static var OR_MORE_LESS = SKIP_WS("or".string()) + MORE_LESS / "or (more|less)";

  static var times = [
    "once".string().result(1),
    "twice".string().result(2),
    "thrice".string().result(3),
    SKIP_OWS(positive).skip("times".string())
  ].alt() / "times";

// POSITIVE_SEQUENCE = OPEN_PAREN, { WS }, POSITIVE, { WS }, {COMMA, { WS }, POSITIVE, { WS } }, CLOSE_PAREN;
// MATCH =
//   POSITIVE, [ OR_MORE_LESS ] |
//   (POSITIVE, { WS }, "...", { WS }, POSITIVE) |
//   POSITIVE_SEQUENCE;
// MAP_KEY_VALUE_PAIR = MATCH,  { WS }, ":", { WS }, NUMBER;
// MAP_SEQUENCE = OPEN_PAREN, { WS }, MAP_KEY_VALUE_PAIR, { WS }, {COMMA, { WS }, MAP_KEY_VALUE_PAIR, { WS } }, CLOSE_PAREN;


  static var basicLiteral = positive.map.fn(Literal(_, unit)) / "basic literal";
  static var literal = basicLiteral.map(Roll) / "literal";
  static function toDie(sides: Int) return new Die(sides, unit);
  
  static var DEFAULT_DIE_SIDES = 6;
  static var die = [
      (D + PERCENT).result(toDie(100)),
      (D + positive).map(toDie),
      D.result(toDie(DEFAULT_DIE_SIDES))
    ].alt() / "one die";

  static var basicDice = [
    positive.flatMap(function(rolls) {
      return die.map(function(die) {
        return if(rolls == 1) {
          One(die);
        } else {
          Repeat(rolls, die, unit);
        }
      });
    }),
    die.map.fn(One(_))
  ].alt() / "basic dice";
  // static var dice = basicDice.map(Roll) / "dice";

  static var basicDiceSetElement = [
    basicDice,
    basicLiteral
  ].alt() / "dice set element";

  static var basicDiceSet: ParseObject<BasicRoll<Unit>> = function() {
    return [
      OPEN_SET_BRACKET + OWS + [
        basicDiceSetElement,
        basicDiceSet
      ].alt().sepBy(OWS + ",".string() + OWS).skip(OWS + CLOSE_SET_BRACKET).map(function(arr) {
        return Bag(arr, unit);
      }),
      basicDice
    ].alt();
  }.lazy() / "dice set";

  static var diceSet = basicDiceSet.map(Roll) / "dice set";

  static var basicExpressionSet: ParseObject<Array<DiceExpression<Unit>>> = function() {
    return OPEN_SET_BRACKET + OWS +
      expression
        .sepBy(OWS + ",".string() + OWS)
        .skip(OWS + CLOSE_SET_BRACKET);
  }.lazy() / "expression set";

  static var expressionSetSum: ParseObject<DiceExpression<Unit>> = 
    basicExpressionSet.map.fn(RollExpressions(_, Sum, unit)) / "expression set";

  static var negate: ParseObject<DiceExpression<Unit>> = function() {
    return MINUS + inlineExpression.map(function(expr) {
      return UnaryOp(Negate, expr, unit);
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
        inlineExpression.map(function(b: DiceExpression<Unit>) {
          return { op: o, right: b };
        });
    });

  static var binop: ParseObject<DiceExpression<Unit>> =
    function() {
      return inlineExpression.flatMap(
        function(left: DiceExpression<Unit>) {
          return opRight.times(1, 1000).map(function(a) {
            return a.reduce(function(left, item) {
              return switch item.op {
                case Sum | Difference:
                  return BinaryOp(item.op, left, item.right, unit);
                case Multiplication | Division: // this seems too complicated but it works for now
                  return switch left {
                    case BinaryOp(o, l, r, _):
                      BinaryOp(o, l, BinaryOp(item.op, r, item.right, unit), unit);
                    case other:
                      BinaryOp(item.op, left, item.right, unit);
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

  static var inlineExpression: ParseObject<DiceExpression<Unit>> = function() {
    return [
      expressionSetSum,
      diceSet,
      literal,
      negate
    ].alt();
  }.lazy() / "inline expression";

  static var expression: ParseObject<DiceExpression<Unit>> = function() {
    return [
      expressionOperations,
      inlineExpression
    ].alt();
  }.lazy() / "expression";

  static var grammar = 
    OWS + expression.skip(OWS).skip(eof());
}
