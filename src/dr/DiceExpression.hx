package dr;

enum DiceExpression {
  Die(sides: Int);
  Dice(times: Int, sides: Int);
  Literal(value: Int);
  DiceMap(dice: Array<Sides>, extractor: DiceFunctor);
  DiceReducer(exprs: Array<DiceExpression>, extractor: DiceReduce);
  BinaryOp(op: DiceBinOp, a: DiceExpression, b: DiceExpression);
  UnaryOp(op: DiceUnOp, a: DiceExpression);
}

enum DiceReduce {
  Sum;
  Average;
  Min;
  Max;
  Drop(dir: LowHigh, value: Int);
  Keep(dir: LowHigh, value: Int);
}

enum DiceFunctor {
  Explode(times: Times, range: Range);
  Reroll(times: Times, range: Range);
}

enum Times {
  Always;
  UpTo(value: Int);
}

enum Range {
  Exact(value: Int);
  Between(minInclusive: Int, maxInclusive: Int);
  ValueOrMore(value: Int);
  ValueOrLess(value: Int);
  Composite(ranges: Array<Range>);
}

enum LowHigh {
  Low;
  High;
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
