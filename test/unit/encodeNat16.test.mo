import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat16 "mo:base/Nat16";

import NatX "mo:xtended-numbers/NatX";

for (i in Iter.range(0, 2009)) {
  let buf = Buffer.fromArray<Nat8>([7]);
  NatX.encodeNat16(buf, Nat16.fromNat(i), #msb);
  Debug.print(debug_show(Buffer.toArray(buf)));
  assert(buf.size() == 3);
}
