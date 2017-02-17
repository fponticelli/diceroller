package dapi;

typedef DiceResult<T> = DiceExpression<DiceResultMeta<T>>;

class DiceResults {
  public static function extractResult<T>(expr: DiceResult<T>): Int {
    return switch expr {
      case RollOne(die):
        die.meta.result;
      case RollGroup(_, _, meta) |
           RollAndDropLow(_, _, meta) |
           RollAndKeepHigh(_, _, meta) | 
           RollAndExplode(_, _, meta) |
           BinaryOp(_, _, _, meta) |
           Literal(_, meta):
        meta.result;
    };
  }
}