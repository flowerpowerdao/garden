export const idlFactory = ({ IDL }) => {
  const Duration = IDL.Variant({
    'nanoseconds' : IDL.Nat,
    'hours' : IDL.Nat,
    'days' : IDL.Nat,
    'minutes' : IDL.Nat,
    'seconds' : IDL.Nat,
  });
  const InitArgs = IDL.Record({
    'minStakePeriod' : Duration,
    'seedRewardPerHour' : IDL.Nat,
  });
  const AccountIdentifier = IDL.Text;
  const anon_class_5_1 = IDL.Service({
    'getStakingAccountId' : IDL.Func([IDL.Principal], [AccountIdentifier], []),
  });
  return anon_class_5_1;
};
export const init = ({ IDL }) => {
  const Duration = IDL.Variant({
    'nanoseconds' : IDL.Nat,
    'hours' : IDL.Nat,
    'days' : IDL.Nat,
    'minutes' : IDL.Nat,
    'seconds' : IDL.Nat,
  });
  const InitArgs = IDL.Record({
    'minStakePeriod' : Duration,
    'seedRewardPerHour' : IDL.Nat,
  });
  return [IDL.Principal, InitArgs];
};
