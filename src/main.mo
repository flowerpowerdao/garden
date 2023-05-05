import Garden "./garden";

actor class(selfId : Principal) {
  let garden = Garden.Garden(selfId);
};