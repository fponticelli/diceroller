package dapi;

enum DiceExpression<T> {
  RollOne(die: Die<T>);
  RollBag(dice: DiceBag<T>, extractor: BagExtractor, meta: T);
  BinaryOp(op: DiceOperator, a: DiceExpression<T>, b: DiceExpression<T>, meta: T);
  Literal(value: Int, meta: T);
}

enum BagExtractor {
  Sum;
  DropLow(drop: Int);
  KeepHigh(keep: Int);
  ExplodeOn(explodeOn: Int);
}

enum DiceBag<T> {
  DiceSet(dice: Array<Die<T>>);
  RepeatDie(times: Int, die: Die<T>);
}

enum DiceOperator {
  Sum;
  Difference;
}
