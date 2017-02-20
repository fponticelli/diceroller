package dr;

enum DiceExpression<T> {
  Roll(basic: BasicRoll<T>);
  RollBag(dice: DiceBag<T>, extractor: BagExtractor, meta: T);
  RollExpressions(exprs: Array<DiceExpression<T>>, extractor: ExpressionExtractor, meta: T);
  BinaryOp(op: DiceBinOp, a: DiceExpression<T>, b: DiceExpression<T>, meta: T);
  UnaryOp(op: DiceUnOp, a: DiceExpression<T>, meta: T);
}

enum BagExtractor {
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
  Average;
  DropLow(drop: Int);
  KeepHigh(keep: Int);
}

enum DiceBinOp {
  Sum;
  Difference;
  Division;
  Multiplication;
}

enum DiceUnOp {
  Negate;
}
