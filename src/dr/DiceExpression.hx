package dr;

enum DiceExpression {
  Die(sides: Sides);
  Literal(value: Int);
  DiceReduce(reduceable: DiceReduceable, reducer: DiceReducer);
  BinaryOp(op: DiceBinOp, a: DiceExpression, b: DiceExpression);
  UnaryOp(op: DiceUnOp, a: DiceExpression);
}

enum DiceReducer {
  Sum;
  Average;
  Min;
  Max;
}

enum DiceReduceable {
  DiceExpressions(exprs: Array<DiceExpression>);
  DiceListWithFilter(list: DiceFilterable, filter: DiceFilter);
  DiceListWithMap(dice: Array<Sides>, functor: DiceFunctor);
}

enum DiceFilterable {
  DiceArray(dice: Array<Sides>);
  DiceExpressions(exprs: Array<DiceExpression>);
}

enum DiceFilter {
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
