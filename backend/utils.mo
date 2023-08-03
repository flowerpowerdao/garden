import Types "./types";

module {
  public func toNanos(duration : Types.Duration) : Nat {
    switch (duration) {
      case (#nanoseconds(ns)) ns;
      case (#seconds(s)) s * 1_000_000_000;
      case (#minutes(m)) m * 1_000_000_000 * 60;
      case (#hours(h)) h * 1000_000_000 * 60 * 60;
      case (#days(d)) d * 1000_000_000 * 60 * 60 * 24;
    };
  };
};