package dr;

import parsihax.*;
import parsihax.Parser.*;
using parsihax.Parser;
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

  // public static function parseDie(s: String): Validation<String, Die<Unit>> {
  //   return switch dN.apply(s) {
  //     case { status: true, value: value }:
  //       Validation.success(value);
  //     case v:
  //       var msg = 'expected ${v.expected.join(" or ")} within "${s}"';
  //       Validation.failure(msg);
  //   }
  // }

  // static var WS = ~/\s*/m.regexp();
  // static function token(parser)
  //   return skip(parser, WS);
  // static var positive = ~/[1-9][0-9]*/.regexp().map(Std.parseInt).as('positive number');
  // static var dN = [
  //     "d".char(),
  //     "D".char()
  //   ].alt()
  //     .then(positive.map(Die.new.bind(_, unit)))
  //     .as("dN");

  // static var rollOne = dN.map(RollOne);
  // static var literal = positive.map(Literal.bind(_, unit)).as("literal number");
  // static var rollManySame = positive.flatMap(function(dice) {
  //   return dN.map.fn(RollBag(RepeatDie(dice, _), Sum, unit)); // TODO add other ops
  // });
  // static var lbrace = token('{'.string());
  // static var rbrace = '}'.string();
  // static function commaSep(parser)
  //   return sepBy(parser, token(','.string()));

  // static var rollMany = lbrace
  //   .then(commaSep(dN))
  //   .skip(rbrace)
  //   .map.fn(RollBag(DiceSet(_), Sum, unit)); // TODO add other ops



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



  static var literal = positive.map.fn(Roll(Literal(_, unit))) / "literal";
  static function toDie(sides: Int) return new Die(sides, unit);
  
  static var DEFAULT_DIE_SIDES = 6;
  static var die = [
      (D + PERCENT).result(toDie(100)),
      (D + positive).map(toDie),
      D.result(toDie(DEFAULT_DIE_SIDES))
    ].alt() / "one die";
  static var dice = [
    positive.flatMap(function(rolls) {
      return die.map(function(die) {
        return if(rolls == 1) {
          Roll(One(die));
        } else {
          RollBag(RepeatDie(rolls, die), Sum, unit);
        }
      });
    }),
    die.map.fn(Roll(One(_)))
  ].alt() / "dice";
  

  static var INLINE_EXPRESSION = [
    dice,
    literal
  ].alt() / "expression";

  static var grammar = 
    OWS + INLINE_EXPRESSION.skip(OWS).skip(eof());
}
