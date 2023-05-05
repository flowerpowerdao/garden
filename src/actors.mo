import Types "./types";
import Ext "./interfaces/ext";
import ICRC1 "./interfaces/icrc1";

module {
  public let btcFlower = actor("pk6rk-6aaaa-aaaae-qaazq-cai") : Ext.Service;
  public let ethFlower = actor("dhiaa-ryaaa-aaaae-qabva-cai") : Ext.Service;
  public let icpFlower = actor("4ggk4-mqaaa-aaaae-qad6q-cai") : Ext.Service;
  public let seed = actor("4ggk4-mqaaa-aaaae-qad6q-cai") : ICRC1.Service;

  public func getActor(collection : Types.Collection) : Ext.Service {
    switch (collection) {
      case (#BTCFlower) btcFlower;
      case (#ETHFlower) ethFlower;
      case (#ICPFlower) icpFlower;
    };
  };
};