package dr;

class RollResultExtensions {
  public static function getResult<T>(expr: RollResult<T>): T {
    return switch expr {
      case OneResult(die):
        die.result;
      case DiceMapResult(_, _, result) |
           DiceReducerResult(_, _, result) |
           BinaryOpResult(_, _, _, result) |
           UnaryOpResult(_, _, result) |
           LiteralResult(_, result):
        result;
    };
  }
}