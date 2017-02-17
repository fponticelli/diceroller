package dapi;

import thx.Unit;

enum DiceExpression<T> {
  RollOne(die: Die<T>);
  RollMany(dice: Array<Die<T>>, meta: T);
  RollAndDropLow(dice: Array<Die<T>>, drop: Int, meta: T);
  RollAndKeepHigh(dice: Array<Die<T>>, keep: Int, meta: T);
  RollAndExplode(dice: Array<Die<T>>, explodeOn: Int, meta: T);
  BinaryOp(op: DiceOperator, a: DiceExpression<T>, b: DiceExpression<T>, meta: T);
}

enum DiceOperator {
  Sum;
  Difference;
}
