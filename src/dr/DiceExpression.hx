package dr;

enum DiceExpression<T> {
  Roll(basic: BasicRoll<T>);
  RollBag(dice: DiceBag<T>, extractor: BagExtractor, meta: T);
  RollExpressions(exprs: ExpressionBag<T>, extractor: ExpressionExtractor, meta: T);
  BinaryOp(op: DiceOperator, a: DiceExpression<T>, b: DiceExpression<T>, meta: T);
}

enum BagExtractor {
  Sum;
  DropLow(drop: Int);
  KeepHigh(keep: Int);
  ExplodeOn(explodeOn: Int);
}

enum BasicRoll<T> {
  One(die: Die<T>);
  Bag(list: Array<BasicRoll<T>>, meta: T);
  Repeat(times: Int, die: Die<T>, meta: T);
  Literal(value: Int, meta: T);
}

enum DiceBag<T> {
  DiceSet(dice: Array<Die<T>>);
  RepeatDie(times: Int, die: Die<T>);
}

enum ExpressionExtractor {
  Sum;
  DropLow(drop: Int);
  KeepHigh(keep: Int);
}

enum ExpressionBag<T> {
  ExpressionSet(exprs: Array<DiceExpression<T>>);
  RepeatDie(times: Int, die: Die<T>);
}

enum DiceOperator {
  Sum;
  Difference;
}
