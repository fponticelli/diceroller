import utest.Assert;
import utest.UTest;
using dapi.DiceExpression;
using dapi.DiceExpressionExtensions;
import dapi.DiceResult;
import dapi.DiceParser;
import dapi.Die;
import dapi.Roller;
import dapi.SimpleDiceDSL.*;

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

  // public function testSimpleDSL() {
  //   var e = subtract(add(die(6), dropLow([d8, d8, d8, d6], 1)), literal(1)),
  //       s = e.toString();
  //   Assert.same(Right(e), DiceParser.parse(s));
  // }

  public function testParseDie() {
    assertParseDie(d8, "d8");
    assertParseDie(d12, "D12");
  }

  public function testParse() {
    var tests: Array<DiceExpression<thx.Unit>> = [
      die(6),
      literal(2),
      many(3, d6),
      dice([d2, d4, d6])
    ];
    for(test in tests)
      assertParseExpression(test);
  }

  public function assertParseDie(expected: Die<thx.Unit>, test: String) {
    var parsed = DiceParser.parseDie(test);
    switch parsed.either {
      case Left(e):
        Assert.fail(e);
      case Right(v):
        Assert.same(expected, v);
    }
  }

  public function assertParseExpression(exp: DiceExpression<thx.Unit>) {
    var test = exp.toString();
    trace(test);
    var parsed = DiceParser.parse(test);
    switch parsed.either {
      case Left(e):
        Assert.fail(e);
      case Right(v):
        Assert.same(exp, v, 'expected $exp but it is $v for $test');
    }
  }
}