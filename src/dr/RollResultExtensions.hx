package dr;

class RollResultExtensions {
  public static function getResult(expr: RollResult): Int {
    return switch expr {
      case OneResult(die):
        die.result;
      case DiceReduceResult(_, _, result) |
           BinaryOpResult(_, _, _, result) |
           UnaryOpResult(_, _, result) |
           LiteralResult(_, result):
        result;
    };
  }
}
