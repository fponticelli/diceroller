import utest.Assert;
import utest.UTest;
using dr.DiceExpressionExtensions;
using dr.DiceResult;
import dr.DiceParser;
import dr.Roller;

class TestAll {
  public static function main() {
    UTest.run([
      new TestAll()
    ]);
  }

  public function new() {}

  public function testRoller() {
    var r = roller().rollDice(12, 6);
    Assert.equals(42, DiceResults.extractResult(r));

    r = roller().rollOne(6);
    Assert.equals(1, DiceResults.extractResult(r));
    r = roller(2).rollOne(6);
    Assert.equals(2, DiceResults.extractResult(r));

    r = roller().rollDiceAndDropLow(5, 6, 2);
    Assert.equals(12, DiceResults.extractResult(r));

    r = roller().rollDiceAndKeepHigh(5, 6, 2);
    Assert.equals(9, DiceResults.extractResult(r));

    r = roller().rollDiceAndExplode(5, 6, 5);
    Assert.equals(15+6+1, DiceResults.extractResult(r));
  }

  public function roller(seq = 1)
    return new Roller(function(max: Int) return ((seq++ - 1) % max) + 1);

  public function max()
    return new Roller(function(max: Int) return max);

  public function min()
    return new Roller(function(_: Int) return 1);

  public function testParseAndBoundaries() {
    var tests: Array<TestObject> = [
      { min: 1, max: 1, t: "1", pos: pos() },
      { min: 2, max: 2, t: "2", pos: pos() },
      { min: 1, max: 6, t: "D", p: "d6", pos: pos() },
      { min: 1, max: 6, t: "d", p: "d6", pos: pos() },
      { min: 1, max: 6, t: "1d", p: "d6", pos: pos() },
      { min: 1, max: 6, t: "1D", p: "d6", pos: pos() },
      { min: 1, max: 6, t: "1d6", p: "d6", pos: pos() },
      { min: 1, max: 6, t: "1D6", p: "d6", pos: pos() },
      { min: 1, max: 6, t: "d6", pos: pos() },
      { min: 1, max: 6, t: "D6", p: "d6", pos: pos() },
      { min: 1, max: 6, t: " d6 ", p: "d6", pos: pos() },
      { min: 1, max: 6, t: "d6 ", p: "d6", pos: pos() },
      { min: 1, max: 6, t: " d6", p: "d6", pos: pos() },
      { min: 1, max: 100, t: "d%", pos: pos() },
      { min: 3, max: 300, t: "3d100", p: "3d%", pos: pos() },

      { min: 1, max: 8, t: "{d8}", pos: pos() },
      { min: 2, max: 2, t: "{2}", pos: pos() },
      { min: 5, max: 5, t: "{2,3}", pos: pos() },
      { min: 2, max: 6, t: "{2d3}", pos: pos() },
      { min: 2, max: 14, t: "{d6,d8}", pos: pos() },
      { min: 2, max: 14, t: "{ d6 , d8 }", p: "{d6,d8}", pos: pos() },
      { min: 3, max: 18, t: "{d4,d6,d8}", pos: pos() },
      { min: 5, max: 20, t: "{2,d4,d6,d8}", pos: pos() },
      { min: 6, max: 30, t: "{2,d4,3d8}", pos: pos() },
      { min: 10, max: 58, t: "{{2,d4,3d8},d4,3d8}", pos: pos() },

      { min: -6, max: -6, t: "-6", pos: pos() },
      { min: -1, max: -6, t: "-d6", pos: pos() },
      { min: -2, max: -10, t: "-{d6,d4}", pos: pos() },
      { min: 5, max: 5, t: "2+3", p: "2 + 3", pos: pos() },
      { min: 1, max: 1, t: "2-1", p: "2 - 1", pos: pos() },
      { min: 0, max: 0, t: "2-1-1", p: "2 - 1 - 1", pos: pos() },
      { min: 6, max: 25, t: "3 + d6 + 2d8", pos: pos() },
      { min: 0, max: 19, t: "-3 + d6 + 2d8", pos: pos() },
      { min: -2, max: 7, t: "-3 + -d6 + 2d8", pos: pos() },
      { min: 5, max: 24, t: "d6 + 2d8 + 2", pos: pos() },
      { min: 1, max: 48, t: "d6 * 2d8 / 2", pos: pos() },
      { min: 14, max: 14, t: "2 + 3 * 4", pos: pos() },
      { min: -10, max: -10, t: "2 + -3 * 4", pos: pos() },
      { min: -10, max: -10, t: "2 + 3 * -4", pos: pos() },
      { min: 10, max: 10, t: "-2 + 3 * 4", pos: pos() },
      { min: 14, max: 14, t: "2 + {3 * 4}", pos: pos() },

      { min: 4, max: 4, t: "100 / 25", pos: pos() },
      { min: 75, max: 75, t: "25 * 3", pos: pos() },
      { min: 2, max: 2, t: "150 / 25 * 3", pos: pos() },
      { min: 11, max: 105, t: "{{2,d4,3d8},5} * {d4,3d8} / {3,d6}", pos: pos() },
    ];
    
    tests.map(assertParseAndBoundaries);
  }

  public function assertParseAndBoundaries(t: TestObject) {
    var parsed = DiceParser.parse(t.t);
    switch parsed.either {
      case Left(e):
        Assert.fail(e, t.pos);
      case Right(v):
        var serialized = v.toString();
        var expected = null == t.p ? t.t : t.p;
        var f = t.t != expected ? ' for "${t.t}"' : "";
        Assert.equals(expected, serialized, 'expected serialization to be "${expected}" but it is "${serialized}"$f', t.pos);
        var minr = min().roll(v).extractResult();
        Assert.equals(t.min, minr, 'expected min to be ${t.min} but it is $minr', t.pos);
        var maxr = max().roll(v).extractResult();
        Assert.equals(t.max, maxr, 'expected max to be ${t.max} but it is $maxr', t.pos);
    }
  }

  inline public function pos(?pos: haxe.PosInfos) return pos;
}

typedef TestObject = {
  min: Int,
  max: Int,
  t: String,
  ?p: String,
  pos: haxe.PosInfos
}