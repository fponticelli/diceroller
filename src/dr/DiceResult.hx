package dr;

typedef DiceResult<T> = DiceExpression<DiceResultMeta<T>>;

class DiceResults {
  public static function extractResult<T>(expr: DiceResult<T>): Int {
    return switch expr {
      case Roll(One(die)):
        die.meta.result;
      case RollBag(_, _, meta) |
           RollExpressions(_, _, meta) |
           BinaryOp(_, _, _, meta) |
           UnaryOp(_, _, meta) |
           Roll(Bag(_, meta)) |
           Roll(Repeat(_, _, meta)) |
           Roll(Literal(_, meta)):
        meta.result;
    };
  }
}