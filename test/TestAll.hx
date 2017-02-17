import utest.Assert;
import utest.UTest;
import thx.Unit;

import dapi.DiceExpression;
import dapi.DiceResult;
import dapi.Roller;

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
}