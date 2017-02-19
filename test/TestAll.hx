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
        var maxr = min().roll(v).extractResult();
        Assert.equals(t.min, maxr, 'expected max to be ${t.min} but it is $maxr', t.pos);
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