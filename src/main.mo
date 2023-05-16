import Garden "./garden";
import Types "./types";

actor class(selfId : Principal, initArgs : Types.InitArgs) {
  let garden = Garden.Garden(selfId, initArgs);
};