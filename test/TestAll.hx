import utest.Assert;
import utest.UTest;
using dr.DiceExpressionExtensions;
import dr.DiceResult;
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
    var tests = [
      { min: 1, max: 6, t: "D", pos: pos() },
      { min: 1, max: 6, t: "d", pos: pos() },
      { min: 1, max: 6, t: "1d", pos: pos() },
      { min: 1, max: 6, t: "1D", pos: pos() },
      { min: 1, max: 6, t: "1d6", pos: pos() },
      { min: 1, max: 6, t: "1D6", pos: pos() },
      { min: 1, max: 6, t: "d6", pos: pos() },
      { min: 1, max: 6, t: "D6", pos: pos() },
    ];
    
    tests.map(assertParseAndBoundaries);
  }

  public function assertParseAndBoundaries(t: {min: Int, max: Int, t: String, ?p: String, pos: haxe.PosInfos}) {
    var parsed = DiceParser.parse(t.t);
    switch parsed.either {
      case Left(e):
        Assert.fail(e, t.pos);
      case Right(v):
        var serialized = v.toString();
        var expected = null == t.p ? t.t : t.p;
        Assert.same(expected, serialized, t.pos);

        Assert.equals(t.min, min().roll(v), t.pos);
        Assert.equals(t.max, max().roll(v), t.pos);
    }
  }

  inline public function pos(?pos: haxe.PosInfos) return pos;
}