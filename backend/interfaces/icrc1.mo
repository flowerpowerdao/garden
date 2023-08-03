module {
  public type Account = { owner : Principal; subaccount : ?Subaccount };
  // Number of nanoseconds between two [Timestamp]s.
  public type Duration = Nat64;
  public type Subaccount = [Nat8];
  // Number of nanoseconds since the UNIX epoch in UTC timezone.
  public type Timestamp = Nat64;
  public type TransferArgs = {
    to : Account;
    fee : ?Nat;
    memo : ?[Nat8];
    from_subaccount : ?Subaccount;
    created_at_time : ?Timestamp;
    amount : Nat;
  };
  public type TransferError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #CreatedInFuture : { ledger_time : Timestamp };
    #TooOld;
    #InsufficientFunds : { balance : Nat };
  };
  public type Value = { #Int : Int; #Nat : Nat; #Blob : [Nat8]; #Text : Text };
  public type Service = actor {
    icrc1_balance_of : shared query Account -> async Nat;
    icrc1_decimals : shared query () -> async Nat8;
    icrc1_fee : shared query () -> async Nat;
    icrc1_metadata : shared query () -> async [(Text, Value)];
    icrc1_minting_account : shared query () -> async ?Account;
    icrc1_name : shared query () -> async Text;
    icrc1_supported_standards : shared query () -> async [
      { url : Text; name : Text }
    ];
    icrc1_symbol : shared query () -> async Text;
    icrc1_total_supply : shared query () -> async Nat;
    icrc1_transfer : shared TransferArgs -> async {
      #Ok : Nat;
      #Err : TransferError;
    };
  };
};