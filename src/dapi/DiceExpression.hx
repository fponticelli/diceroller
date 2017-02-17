package dapi;

enum DiceExpression<T> {
  RollOne(die: Die<T>);
  RollGroup(dice: DiceGroup<T>, extractor: GroupExtractor, meta: T);
  BinaryOp(op: DiceOperator, a: DiceExpression<T>, b: DiceExpression<T>, meta: T);
  Literal(value: Int, meta: T);
}

enum GroupExtractor {
  Sum;
  DropLow(drop: Int);
  KeepHigh(keep: Int);
  ExplodeOn(explodeOn: Int);
}

enum DiceGroup<T> {
  DiceList(dice: Array<Die<T>>);
  RepeatDie(time: Int, die: Die<T>);
}

enum DiceOperator {
  Sum;
  Difference;
}
