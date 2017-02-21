import utest.Assert;
import utest.UTest;
using dr.DiceExpressionExtensions;
import dr.DiceParser.*;
import dr.Roller;

class TestAll {
  public static function main() {
    UTest.run([
      new TestAll()
    ]);
  }

  public function new() {}

  public function max()
    return Roller.int(function(max: Int) return max);

  public function discrete()
    return Roller.discrete();

  public function min()
    return Roller.int(function(_: Int) return 1);

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

      { min: 1,  max: 8,  t: "{d8}", p: 'd8', pos: pos() },
      { min: 2,  max: 2,  t: "{2}", p: '2', pos: pos() },
      { min: 5,  t: "{2,3}", pos: pos() },
      { min: 2,  max: 6,  t: "{2d3}", p: '2d3', pos: pos() },
      { min: 2,  max: 14, t: "{d6,d8}", pos: pos() },
      { min: 2,  max: 14, t: "{ d6 , d8 }", p: "{d6,d8}", pos: pos() },
      { min: 3,  max: 18, t: "{d4,d6,d8}", pos: pos() },
      { min: 5,  max: 20, t: "{2,d4,d6,d8}", pos: pos() },
      { min: 6,  max: 30, t: "{2,d4,3d8}", pos: pos() },
      { min: 10, max: 58, t: "{{2,d4,3d8},d4,3d8}", pos: pos() },

      { min: -6,  t: "-6", pos: pos() },
      { min: -1,  max: -6,  t: "-d6", pos: pos() },
      { min: -2,  max: -10, t: "-{d6,d4}", pos: pos() },
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
      { min: 14,  t: "2 + {3 * 4}", pos: pos() },

      { min: 4,  t: "100 / 25", pos: pos() },
      { min: 75, t: "25 * 3", pos: pos() },
      { min: 2,  t: "150 / 25 * 3", pos: pos() },
      { min: 18, t: "{150 / 25} * 3", pos: pos() },
      { min: 11, max: 105, t: "{{2,d4,3d8},5} * {d4,3d8} / {3,d6}", pos: pos() },

      { min: 10, max: 60, t: "10d6", pos: pos() },
      { min: 10, max: 60, t: "10d6 sum", p: "10d6", pos: pos() },
      { min: 1,  max: 6,  t: "10d6 min", pos: pos() },
      { min: 1,  max: 6,  t: "10d6 minimum", p: "10d6 min", pos: pos() },
      { min: 1,  max: 6,  t: "10d6 max", pos: pos() },
      { min: 1,  max: 6,  t: "10d6 maximum", p: "10d6 max", pos: pos() },
      { min: 1,  t: "{1,2,3} min", pos: pos() },
      { min: 3,  t: "{1,2,3} max", pos: pos() },
      { min: 2,  t: "{1,2,3} avg", p: "{1,2,3} average", pos: pos() },
      { min: 1,  max: 6,  t: "3d6 average", pos: pos() },
      { min: 4,  max: 24, t: "{3d6,5d6} average", pos: pos() },
      { min: 2,  t: "{1,2,3} average", pos: pos() },

      { min: 5, t: "{1,2,3} drop lowest 1", p: "{1,2,3} drop 1", pos: pos() },
      { min: 3, t: "{1,2,3} drop lowest 2", p: "{1,2,3} drop 2", pos: pos() },
      { min: 3, t: "{1,2,3} drop low 2", p: "{1,2,3} drop 2", pos: pos() },
      { min: 5, t: "{1,2,3} drop 1", pos: pos() },
      { min: 3, t: "{1,2,3} drop highest 1", pos: pos() },
      { min: 1, t: "{1,2,3} drop highest 2", pos: pos() },
      { min: 1, t: "{1,2,3} drop high 2", p: "{1,2,3} drop highest 2", pos: pos() },
      { min: 3, max: 18, t: "5d6 drop 2", pos: pos() },

      { min: 1, t: "{1,2,3} keep lowest 1", pos: pos() },
      { min: 3, t: "{1,2,3} keep lowest 2", pos: pos() },
      { min: 3, t: "{1,2,3} keep low 2", p: "{1,2,3} keep lowest 2", pos: pos() },
      { min: 3, t: "{1,2,3} keep 1", pos: pos() },
      { min: 3, t: "{1,2,3} keep highest 1", p: "{1,2,3} keep 1", pos: pos() },
      { min: 5, t: "{1,2,3} keep highest 2", p: "{1,2,3} keep 2", pos: pos() },
      { min: 5, t: "{1,2,3} keep high 2", p: "{1,2,3} keep 2", pos: pos() },
      { min: 2, max: 12, t: "5d6 keep 2", pos: pos() },
    ];

    tests.map(assertParseAndBoundaries);
  }

  public function assertParseAndBoundaries(t: TestObject) {
    var parsed = parse(t.t);
    switch parsed.either {
      case Left(e):
        Assert.fail(e, t.pos);
      case Right(v):
        var serialized = v.toString();
        var expected = null == t.p ? t.t : t.p;
        var f = t.t != expected ? ' for "${t.t}"' : "";
        Assert.equals(expected, serialized, 'expected serialization to be "${expected}" but it is "${serialized}"$f', t.pos);
        var minr = min().roll(v).getMeta();
        Assert.equals(t.min, minr, 'expected min to be ${t.min} but it is $minr', t.pos);
        var maxr = max().roll(v).getMeta();
        var expectedmax = null == t.max ? t.min : t.max;
        Assert.equals(expectedmax, maxr, 'expected max to be $expectedmax but it is $maxr', t.pos);
    }
  }

  public function testDiscrete() {
    var expr = unsafeParse("1d6"),
        roller = discrete(),
        discrete = roller.roll(expr).getMeta();
    for(v in discrete.probabilities())
      Assert.floatEquals(0.16666666, v);
    Assert.same([1, 2, 3, 4, 5, 6], discrete.values());
    // trace(roller.roll(unsafeParse("5d6 drop 2")).getMeta().toString());
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