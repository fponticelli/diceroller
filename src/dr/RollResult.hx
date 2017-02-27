package dr;

import dr.DiceExpression;

enum RollResult<T> {
  OneResult(die: DieResult<T>);
  LiteralResult(value: Int, result: T);
  DiceReduceResult(reduceables: DiceReduceableResult<T>, reducer: DiceReducer, result: T);
  BinaryOpResult(op: DiceBinOp, a: RollResult<T>, b: RollResult<T>, result: T);
  UnaryOpResult(op: DiceUnOp, a: RollResult<T>, result: T);
}

enum DiceReduceableResult<T> {
  DiceExpressionsResult(rolls: Array<RollResult<T>>);
  DiceFilterableResult(rolls: Array<DieResultFilter<T>>, filter: DiceFilter);
  DiceMapeableResult(rolls: Array<DiceResultMapped<T>>, functor: DiceFunctor);
}

enum DiceResultMapped<T> {
  Rerolled(rerolls: Array<DieResult<T>>);
  Exploded(explosions: Array<DieResult<T>>);
  Normal(roll: DieResult<T>);
}

typedef DieResult<T> = {
  result: T,
  sides: Sides
}

enum DieResultFilter<T> {
  Keep(roll: RollResult<T>);
  Discard(roll: RollResult<T>);
}