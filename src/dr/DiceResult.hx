package dr;

import dr.DiceExpression;

enum DiceResult<T> {
  Roll(basic: BasicRollResult<T>);
  RollBag(dice: Array<DiceResult<T>>, extractor: BagExtractor, result: T);
  RollExpressions(exprs: Array<DiceResult<T>>, extractor: ExpressionExtractor, result: T);
  BinaryOp(op: DiceBinOp, a: DiceResult<T>, b: DiceResult<T>, result: T);
  UnaryOp(op: DiceUnOp, a: DiceResult<T>, result: T);
}

typedef DieResult<T> = {
  result: T,
  sides: Sides
}

enum BasicRollResult<T> {
  One(die: DieResult<T>);
  Literal(value: Int, result: T);
}
