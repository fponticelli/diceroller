package dr;

import dr.DiceExpression;

enum RollResult<T> {
  OneResult(die: DieResult<T>);
  LiteralResult(value: Int, result: T);
  DiceMapResult(dice: Array<RollResult<T>>, extractor: DiceFunctor, result: T);
  DiceReducerResult(exprs: Array<RollResult<T>>, aggregator: DiceReduce, result: T);
  BinaryOpResult(op: DiceBinOp, a: RollResult<T>, b: RollResult<T>, result: T);
  UnaryOpResult(op: DiceUnOp, a: RollResult<T>, result: T);
}

typedef DieResult<T> = {
  result: T,
  sides: Sides
}