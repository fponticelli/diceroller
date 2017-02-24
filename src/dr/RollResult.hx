package dr;

import dr.DiceExpression;

enum RollResult<T> {
  One(die: DieResult<T>);
  Literal(value: Int, result: T);
  RollBag(dice: Array<RollResult<T>>, extractor: DiceFunctor, result: T);
  RollExpressions(exprs: Array<RollResult<T>>, aggregator: DiceReduce, result: T);
  BinaryOp(op: DiceBinOp, a: RollResult<T>, b: RollResult<T>, result: T);
  UnaryOp(op: DiceUnOp, a: RollResult<T>, result: T);
}

typedef DieResult<T> = {
  result: T,
  sides: Sides
}