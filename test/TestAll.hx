import utest.Assert;
import utest.UTest;
using dr.DiceExpression;
using dr.RollResult;
using dr.DiceExpressionExtensions;
import dr.DiceParser.*;
import dr.Roller;
using dr.RollResultExtensions;

class TestAll {
  public static function main() {
    UTest.run([
      new TestAll()
    ]);
  }

  public function new() {}

  public function max()
    return new Roller(function(max: Int) return max);

  public function min()
    return new Roller(function(_: Int) return 1);

  public function testRoller() {
    var tests = [
      {
        test: Die(6),
        min: OneResult({ result: 1, sides: 6 }),
        max: OneResult({ result: 6, sides: 6 }), pos: pos()
      }, {
        test: Literal(6),
        min: LiteralResult(6, 6),
        max: LiteralResult(6, 6), pos: pos()
      }, {
        test: DiceReduce(DiceExpressions([Literal(1), Literal(2), Literal(3)]), Sum),
        min: DiceReduceResult(DiceExpressionsResult([LiteralResult(1,1), LiteralResult(2,2), LiteralResult(3,3)]), Sum, 6),
        max: DiceReduceResult(DiceExpressionsResult([LiteralResult(1,1), LiteralResult(2,2), LiteralResult(3,3)]), Sum, 6), pos: pos()
      }, {
        test: DiceReduce(DiceExpressions([Literal(1), Literal(2), Literal(3)]), Average),
        min: DiceReduceResult(DiceExpressionsResult([LiteralResult(1,1), LiteralResult(2,2), LiteralResult(3,3)]), Average, 2),
        max: DiceReduceResult(DiceExpressionsResult([LiteralResult(1,1), LiteralResult(2,2), LiteralResult(3,3)]), Average, 2), pos: pos()
      }, {
        test: DiceReduce(DiceExpressions([Literal(1), Literal(2), Literal(3)]), Min),
        min: DiceReduceResult(DiceExpressionsResult([LiteralResult(1,1), LiteralResult(2,2), LiteralResult(3,3)]), Min, 1),
        max: DiceReduceResult(DiceExpressionsResult([LiteralResult(1,1), LiteralResult(2,2), LiteralResult(3,3)]), Min, 1), pos: pos()
      }, {
        test: DiceReduce(DiceExpressions([Literal(1), Literal(2), Literal(3)]), Max),
        min: DiceReduceResult(DiceExpressionsResult([LiteralResult(1,1), LiteralResult(2,2), LiteralResult(3,3)]), Max, 3),
        max: DiceReduceResult(DiceExpressionsResult([LiteralResult(1,1), LiteralResult(2,2), LiteralResult(3,3)]), Max, 3), pos: pos()
      }, {
        test: DiceReduce(DiceListWithFilter(DiceExpressions([Literal(1), Literal(2), Literal(3)]), Drop(Low, 1)), Sum),
        min: DiceReduceResult(DiceFilterableResult([Discard(LiteralResult(1, 1)), Keep(LiteralResult(2, 2)), Keep(LiteralResult(3, 3))], Drop(Low, 1)), Sum, 5),
        max: DiceReduceResult(DiceFilterableResult([Discard(LiteralResult(1, 1)), Keep(LiteralResult(2, 2)), Keep(LiteralResult(3, 3))], Drop(Low, 1)), Sum, 5), pos: pos()
      }, {
        test: DiceReduce(DiceListWithMap([2,3,4], Explode(UpTo(1), ValueOrMore(3))), Sum),
        min: DiceReduceResult(DiceMapeableResult([
          Normal({result:1, sides:2}),
          Normal({result:1, sides:3}),
          Normal({result:1, sides:4})
        ], Explode(UpTo(1), ValueOrMore(3))), Sum, 3),
        max: DiceReduceResult(DiceMapeableResult([
          Normal({result:2, sides:2}),
          Exploded([{result:3, sides:3}, {result:3, sides:3}]),
          Exploded([{result:4, sides:4}, {result:4, sides:4}])
        ], Explode(UpTo(1), ValueOrMore(3))), Sum, 16), pos: pos()
      }, {
        test: DiceReduce(DiceListWithMap([2,3,4], Reroll(UpTo(1), ValueOrMore(3))), Sum),
        min: DiceReduceResult(DiceMapeableResult([
          Normal({result:1, sides:2}),
          Normal({result:1, sides:3}),
          Normal({result:1, sides:4})
        ], Reroll(UpTo(1), ValueOrMore(3))), Sum, 3),
        max: DiceReduceResult(DiceMapeableResult([
          Normal({result:2, sides:2}),
          Rerolled([{result:3, sides:3}, {result:3, sides:3}]),
          Rerolled([{result:4, sides:4}, {result:4, sides:4}])
        ], Reroll(UpTo(1), ValueOrMore(3))), Sum, 9), pos: pos()
      }, {
        test: BinaryOp(Sum, Literal(3), Die(2)),
        min: BinaryOpResult(
          Sum,
          LiteralResult(3, 3),
          OneResult({ result: 1, sides: 2 }),
          4
        ),
        max: BinaryOpResult(
          Sum,
          LiteralResult(3, 3),
          OneResult({ result: 2, sides: 2 }),
          5
        ), pos: pos()
      }, {
        test: UnaryOp(Negate, Literal(3)),
        min: UnaryOpResult(
          Negate,
          LiteralResult(3, 3),
          -3
        ),
        max: UnaryOpResult(
          Negate,
          LiteralResult(3, 3),
          -3
        ), pos: pos()
      }
    ];
    for(test in tests) {
      Assert.same(test.min, min().roll(test.test), test.pos);
      Assert.same(test.max, max().roll(test.test), test.pos);
    }
  }

  public function testParseAndBoundaries() {
    var tests: Array<TestObject> = [
      { min: 1, t: "1", pos: pos() },
      { min: 2, t: "2", pos: pos() },
      { min: 1, max: 6,   t: "D", p: "d6", pos: pos() },
      { min: 1, max: 6,   t: "d", p: "d6", pos: pos() },
      { min: 1, max: 6,   t: "1d", p: "d6", pos: pos() },
      { min: 1, max: 6,   t: "1D", p: "d6", pos: pos() },
      { min: 1, max: 6,   t: "1d6", p: "d6", pos: pos() },
      { min: 1, max: 6,   t: "1D6", p: "d6", pos: pos() },
      { min: 1, max: 6,   t: "d6", pos: pos() },
      { min: 1, max: 6,   t: "D6", p: "d6", pos: pos() },
      { min: 1, max: 6,   t: " d6 ", p: "d6", pos: pos() },
      { min: 1, max: 6,   t: "d6 ", p: "d6", pos: pos() },
      { min: 1, max: 6,   t: " d6", p: "d6", pos: pos() },
      { min: 1, max: 100, t: "d%", pos: pos() },
      { min: 3, max: 300, t: "3d100", p: "3d%", pos: pos() },

      { min: 1,  max: 8,  t: "(d8)", p: 'd8', pos: pos() },
      { min: 2,  max: 2,  t: "(2)", p: '2', pos: pos() },
      { min: 5,  t: "(2,3)", pos: pos() },
      { min: 2,  max: 6,  t: "(2d3)", p: '2d3', pos: pos() },
      { min: 2,  max: 14, t: "(d6,d8)", pos: pos() },
      { min: 2,  max: 14, t: "( d6 , d8 )", p: "(d6,d8)", pos: pos() },
      { min: 3,  max: 18, t: "(d4,d6,d8)", pos: pos() },
      { min: 5,  max: 20, t: "(2,d4,d6,d8)", pos: pos() },
      { min: 6,  max: 30, t: "(2,d4,3d8)", pos: pos() },
      { min: 10, max: 58, t: "((2,d4,3d8),d4,3d8)", pos: pos() },

      { min: -6,  t: "-6", pos: pos() },
      { min: -1, max: -6, t: "-d6", pos: pos() },
      { min: -1,  max: -6,  t: "-d6", pos: pos() },
      { min: -2,  max: -10, t: "-(d6,d4)", pos: pos() },
      { min: 5,   t: "2+3", p: "2 + 3", pos: pos() },
      { min: 1,   t: "2-1", p: "2 - 1", pos: pos() },
      { min: 0,   t: "2-1-1", p: "2 - 1 - 1", pos: pos() },
      { min: 6,   max: 25,  t: "3 + d6 + 2d8", pos: pos() },
      { min: 0,   max: 19,  t: "-3 + d6 + 2d8", pos: pos() },
      { min: -2,  max: 7,   t: "-3 + -d6 + 2d8", pos: pos() },
      { min: 5,   max: 24,  t: "d6 + 2d8 + 2", pos: pos() },
      { min: 1,   max: 48,  t: "d6 * 2d8 / 2", pos: pos() },
      { min: 14,  max: 14,  t: "2 + 3 * 4", pos: pos() },
      { min: -10, t: "2 + -3 * 4", pos: pos() },
      { min: -10, t: "2 + 3 * -4", pos: pos() },
      { min: 10,  t: "-2 + 3 * 4", pos: pos() },
      { min: 14,  t: "2 + (3 * 4)", pos: pos() },

      { min: 4,  t: "100 / 25", pos: pos() },
      { min: 75, t: "25 * 3", pos: pos() },
      { min: 2,  t: "150 / 25 * 3", pos: pos() },
      { min: 18, t: "(150 / 25) * 3", pos: pos() },
      { min: 11, max: 105, t: "((2,d4,3d8),5) * (d4,3d8) / (3,d6)", pos: pos() },

      { min: 10, max: 60, t: "10d6", pos: pos() },
      { min: 10, max: 60, t: "10d6 sum", p: "10d6", pos: pos() },
      { min: 1,  max: 6,  t: "10d6 min", pos: pos() },
      { min: 1,  max: 6,  t: "10d6 minimum", p: "10d6 min", pos: pos() },
      { min: 1,  max: 6,  t: "10d6 max", pos: pos() },
      { min: 1,  max: 6,  t: "10d6 maximum", p: "10d6 max", pos: pos() },
      { min: 1,  t: "(1,2,3) min", pos: pos() },
      { min: 3,  t: "(1,2,3) max", pos: pos() },
      { min: 2,  t: "(1,2,3) avg", p: "(1,2,3) average", pos: pos() },
      { min: 1,  max: 6,  t: "3d6 average", pos: pos() },
      { min: 4,  max: 24, t: "(3d6,5d6) average", pos: pos() },
      { min: 2,  t: "(1,2,3) average", pos: pos() },

      { min: 5, t: "(1,2,3) drop lowest 1", p: "(1,2,3) drop 1", pos: pos() },
      { min: 3, t: "(1,2,3) drop lowest 2", p: "(1,2,3) drop 2", pos: pos() },
      { min: 3, t: "(1,2,3) drop low 2", p: "(1,2,3) drop 2", pos: pos() },
      { min: 5, t: "(1,2,3) drop 1", pos: pos() },
      { min: 5, t: "(1,2,3)d1", p: "(1,2,3) drop 1", pos: pos() },
      { min: 3, t: "(1,2,3) drop highest 1", pos: pos() },
      { min: 1, t: "(1,2,3) drop highest 2", pos: pos() },
      { min: 1, t: "(1,2,3) drop high 2", p: "(1,2,3) drop highest 2", pos: pos() },
      { min: 3, max: 18, t: "5d6 drop 2", pos: pos() },

      { min: 1, t: "(1,2,3) keep lowest 1", pos: pos() },
      { min: 3, t: "(1,2,3) keep lowest 2", pos: pos() },
      { min: 3, t: "(1,2,3) keep low 2", p: "(1,2,3) keep lowest 2", pos: pos() },
      { min: 3, t: "(1,2,3) keep 1", pos: pos() },
      { min: 3, t: "(1,2,3) keep highest 1", p: "(1,2,3) keep 1", pos: pos() },
      { min: 5, t: "(1,2,3) keep highest 2", p: "(1,2,3) keep 2", pos: pos() },
      { min: 5, t: "(1,2,3)k2", p: "(1,2,3) keep 2", pos: pos() },
      { min: 5, t: "(1,2,3) keep high 2", p: "(1,2,3) keep 2", pos: pos() },
      { min: 2, max: 12, t: "5d6 keep 2", pos: pos() },

      { min: 3, max: 12, t: "(d2,d3,d4) explode once on 3", pos: pos() },
      { min: 3, max: 54, t: "3d6 explode twice on 6", pos: pos() },
      { min: 3, max: 108, t: "3d6 explode 5 times on 6", pos: pos() },
      { min: 3, max: 18, t: "3d6 explode always on 7", p: "3d6 explode on 7", pos: pos() },
      { min: 3, max: 18, t: "3d6 explode on 7", pos: pos() },
      { min: 1, max: 12, t: "d6 explode once on 6", pos: pos() },
      { min: 1, max: 12, t: "1d6 explode once on 6", pos: pos() },
      { min: 3, max: 18, t: "3d6e7", pos: pos() },

      { min: 3, max: 9,  t: "(d2,d3,d4) reroll once on 1", pos: pos() },
      { min: 3, max: 18, t: "3d6 reroll twice on 6", pos: pos() },
      { min: 3, max: 18, t: "3d6 reroll 5 times on 6", pos: pos() },
      { min: 1, max: 6, t: "d6 reroll once on 6", pos: pos() },
      { min: 1, max: 6, t: "1d6 reroll once on 6", pos: pos() },
      { min: 3, max: 18, t: "3d6r7", pos: pos() },
    ];

    tests.map(assertParseAndBoundaries);
  }

  public function assertParseAndBoundaries(t: TestObject) {
    var parsed = parse(t.t);
    switch parsed.either {
      case Left(e):
        Assert.fail(e.toString(), t.pos);
      case Right(v):
        var serialized = v.toString();
        var expected = null == t.p ? t.t : t.p;
        var f = t.t != expected ? ' for "${t.t}"' : "";
        Assert.equals(expected, serialized, 'expected serialization to be "${expected}" but it is "${serialized}"$f', t.pos);
        var minr = min().roll(v).getResult();
        Assert.equals(t.min, minr, 'expected low to be ${t.min} but it is $minr for ${t.t} evaluated to ${v}', t.pos);
        var maxr = max().roll(v).getResult();
        var expectedmax = null == t.max ? t.min : t.max;
        Assert.equals(expectedmax, maxr, 'expected high to be $expectedmax but it is $maxr for ${t.t} evaluated to ${v}', t.pos);
    }
  }

  inline public function pos(?pos: haxe.PosInfos) return pos;
}

typedef TestObject = {
  min: Int,
  ?max: Int,
  t: String,
  ?p: String,
  pos: haxe.PosInfos
}
