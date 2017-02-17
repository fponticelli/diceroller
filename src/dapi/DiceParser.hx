package dapi;

import parsihax.*;
import parsihax.Parser.*;
using parsihax.Parser;
using thx.Functions;
import thx.Unit;
import thx.Validation;
import dapi.DiceExpression;

class DiceParser {
  public static function parse(s: String): Validation<String, DiceExpression<Unit>> {
    return switch expression.apply(s) {
      case { status: true, value: value }:
        Validation.success(value);
      case v:
        trace(v);
        var sub = s.substring(v.furthest, 40);
        var rest = sub != s ? ' within "${s}"' : "";
        var msg = 'expected ${v.expected.join(" or ")} for "${sub}"$rest';
        Validation.failure(msg);
    };
  }

  public static function parseDie(s: String): Validation<String, Die<Unit>> {
    return switch dN.apply(s) {
      case { status: true, value: value }:
        Validation.success(value);
      case v:
        var msg = 'expected ${v.expected.join(" or ")} within "${s}"';
        Validation.failure(msg);
    }
  }

  static var whitespace = ~/\s*/m.regexp();
  static function token(parser)
    return skip(parser, whitespace);
  static var positive = ~/[1-9][0-9]*/.regexp().map(Std.parseInt).as('positive number');
  static var dN = [
      "d".char(),
      "D".char()
    ].alt()
      .then(positive.map(Die.new.bind(_, unit)))
      .as("dN");

  static var rollOne = dN.map(RollOne);
  static var literal = positive.map(Literal.bind(_, unit)).as("literal number");
  static var rollManySame = positive.flatMap(function(dice) {
    return dN.map.fn(RollGroup(RepeatDie(dice, _), Sum, unit)); // TODO add other ops
  });
  static var lbrace = token('{'.string());
  static var rbrace = '}'.string();
  static function commaSep(parser)
    return sepBy(parser, token(','.string()));

  static var rollMany = lbrace
    .then(commaSep(dN))
    .skip(rbrace)
    .map.fn(RollGroup(DiceList(_), Sum, unit)); // TODO add other ops

/*
  RollAndDropLow(dice: Array<Die<T>>, drop: Int, meta: T);
  RollAndKeepHigh(dice: Array<Die<T>>, keep: Int, meta: T);
  RollAndExplode(dice: Array<Die<T>>, explodeOn: Int, meta: T);
  BinaryOp(op: DiceOperator, a: DiceExpression<T>, b: DiceExpression<T>, meta: T);
*/

  static var expression = whitespace.then([
    rollMany,
    rollManySame,
    rollOne,
    literal
  ].alt());

  // public static function parse(s: String): Either<{ expected: Array<String>, index: Int, furthest: Int }, MetricsQuery> {
  //   var stripped = (~/\s+/g).replace(s, "");
  //   var result = parser.skip(eof()).apply(stripped);
  //   return if (result.status) Right(result.value) else Left(result);
  // }
}
