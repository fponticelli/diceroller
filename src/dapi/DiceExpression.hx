package dapi;

enum DiceExpression<T> {
  RollOne(die: Die<T>);
  RollMany(dice: DiceGroup<T>, meta: T);
  RollAndDropLow(dice: DiceGroup<T>, drop: Int, meta: T);
  RollAndKeepHigh(dice: DiceGroup<T>, keep: Int, meta: T);
  RollAndExplode(dice: DiceGroup<T>, explodeOn: Int, meta: T);
  BinaryOp(op: DiceOperator, a: DiceExpression<T>, b: DiceExpression<T>, meta: T);
  Literal(value: Int, meta: T);
}

enum DiceGroup<T> {
  DiceList(dice: Array<Die<T>>);
  RepeatDie(time: Int, die: Die<T>);
}

enum DiceOperator {
  Sum;
  Difference;
}
