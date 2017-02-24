package dr;

enum DiceExpression {
  Roll(basic: BasicRoll);
  RollBag(dice: DiceBag, extractor: BagExtractor);
  RollExpressions(exprs: Array<DiceExpression>, extractor: ExpressionExtractor);
  BinaryOp(op: DiceBinOp, a: DiceExpression, b: DiceExpression);
  UnaryOp(op: DiceUnOp, a: DiceExpression);
}

enum BagExtractor {
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

enum BasicRoll {
  One(sides: Int);
  Bag(list: Array<BasicRoll>);
  Repeat(times: Int, sides: Int);
  Literal(value: Int);
}

enum DiceBag {
  DiceSet(dice: Array<Sides>);
  RepeatDie(times: Int, sides: Sides);
}

enum ExpressionExtractor {
  Sum;
  Average;
  Min;
  Max;
  Drop(dir: LowHigh, value: Int);
  Keep(dir: LowHigh, value: Int);
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
