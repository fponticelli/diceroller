package dr;

import haxe.ds.Either;

class BoxLattice<H, C> {
  var headers(default, null): Array<Array<H>>;
  var cells(default, null): Array<C>;
  var size(default, null): Int;

  public function new(headers: Array<Array<H>>, cells: Either<C, Array<C>>) {
    this.headers = headers;
    size = 1;
    for(i in 0...dims()) size *= headers[i].length;
    this.cells = switch(cells) {
      case Left(c): [for (j in 0...size) c];
      case Right(c): c;
    }
  }

  public inline function dims() return headers.length;

  public inline function flatten() return cells;

  public function mapcells<D>(f: C -> Array<H> -> D): BoxLattice<H, D> {
    var newcells: Array<D> = [];
    var headerindices: Array<Int> = [for (i in 0...this.headers.length) 0];
    var headervalues: Array<H> = [];
    for(i in 0...size) {
      for(j in 0...dims())
        headervalues[j] = headers[j][headerindices[j]];
      newcells[i] = f(this.cells[i], headervalues);
      headerindices[0]++;
      for(d in 0...(dims() - 1)) {
        if(headerindices[d] >= this.headers[d].length) {
          headerindices[d] = 0;
          headerindices[d + 1]++;
        }
      }
    }
    return new BoxLattice(headers, Right(newcells));
  }

  public function mapheaderstocells<D>(f: Array<H> ->D): BoxLattice<H, D> {
    return this.mapcells(function (c: C, h: Array<H>) { return f(h); });
  }

}
