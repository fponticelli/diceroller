import utest.Assert;
import utest.UTest;
import thx.Unit;

import dapi.DiceExpression;
import dapi.Roller;

class TestAll {
  public static function main() {
    UTest.run([
      new TestAll()
    ]);
  }

  public function new() {}

  public function testRoller() {
    var seq = 0;
    var roller = new Roller(function(max: Int) return (seq++ % max) + 1);

    var r = roller.rollDice(12, 6);
    trace(r);
  }
}