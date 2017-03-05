package dr;

import dr.DiceExpression;

enum RollResult {
  OneResult(die: DieResult);
  LiteralResult(value: Int, result: Int);
  DiceReduceResult(reduceables: DiceReduceableResult, reducer: DiceReducer, result: Int);
  BinaryOpResult(op: DiceBinOp, a: RollResult, b: RollResult, result: Int);
  UnaryOpResult(op: DiceUnOp, a: RollResult, result: Int);
}

enum DiceReduceableResult {
  DiceExpressionsResult(rolls: Array<RollResult>);
  DiceFilterableResult(rolls: Array<DieResultFilter>, filter: DiceFilter);
  DiceMapeableResult(rolls: Array<DiceResultMapped>, functor: DiceFunctor);
}

enum DiceResultMapped {
  Rerolled(rerolls: Array<DieResult>);
  Exploded(explosions: Array<DieResult>);
  Normal(roll: DieResult);
}

typedef DieResult = {
  result: Int,
  sides: Sides
}

enum DieResultFilter {
  Keep(roll: RollResult);
  Discard(roll: RollResult);
}
