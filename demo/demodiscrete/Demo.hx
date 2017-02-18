import dapi.Discrete;

class Demo {
  public static function main() {
    var d6 = Discrete.die(6);
    trace("d6");
    trace(d6.weights());
    trace(d6.probabilities());
    trace(d6.values());

    var twod6: Discrete = d6.binary(d6, function (x: Float, y: Float) { return x + y; });
    trace("2d6 = d6 + d6");
    trace(twod6.weights());
    trace(twod6.probabilities());
    trace(twod6.values());

    var d8 = Discrete.die(8);
    var d12 = Discrete.die(12);
    var dexpr: Discrete;
    trace("2d8 / d12 (for some reason)");
    dexpr = (d8.binary(d8, function (x: Float, y: Float) { return x + y; })).binary(d12, function (x: Float, y: Float) { return x / y; });
    trace(dexpr.weights());
    trace(dexpr.probabilities());
    trace(dexpr.values());
  }
}