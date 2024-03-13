export const idlFactory = ({ IDL }) => {
  const Duration = IDL.Variant({
    'nanoseconds' : IDL.Nat,
    'hours' : IDL.Nat,
    'days' : IDL.Nat,
    'minutes' : IDL.Nat,
    'seconds' : IDL.Nat,
  });
  const InitArgs = IDL.Record({
    'trilogyBonus' : IDL.Nat,
    'rewardInterval' : Duration,
    'stakePeriod' : Duration,
    'dailyRewards' : IDL.Record({
      'btcFlower' : IDL.Nat,
      'btcFlowerGen2' : IDL.Nat,
      'icpFlower' : IDL.Nat,
      'ethFlower' : IDL.Nat,
    }),
  });
  const Account = IDL.Record({
    'owner' : IDL.Principal,
    'subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const NeuronId = IDL.Nat;
  const Time = IDL.Int;
  const Collection = IDL.Variant({
    'BTCFlowerGen2' : IDL.Null,
    'BTCFlower' : IDL.Null,
    'ICPFlower' : IDL.Null,
    'ETHFlower' : IDL.Null,
  });
  const TokenIndex = IDL.Nat;
  const Flower = IDL.Record({
    'collection' : Collection,
    'tokenIndex' : TokenIndex,
  });
  const DissolveState = IDL.Variant({
    'DissolveDelay' : Time,
    'DissolveTimestamp' : Time,
  });
  const Neuron = IDL.Record({
    'id' : IDL.Nat,
    'prevRewardTime' : Time,
    'stakedAt' : Time,
    'flower' : Flower,
    'userId' : IDL.Principal,
    'createdAt' : Time,
    'totalRewards' : IDL.Nat,
    'dissolveState' : DissolveState,
    'stakingAccount' : Account,
  });
  const UserRes = IDL.Record({
    'id' : IDL.Principal,
    'createdAt' : Time,
    'totalRewards' : IDL.Nat,
    'rewards' : IDL.Nat,
    'neurons' : IDL.Vec(Neuron),
  });
  const Result_1 = IDL.Variant({ 'ok' : NeuronId, 'err' : IDL.Text });
  const Main = IDL.Service({
    'claimRewards' : IDL.Func([Account], [Result], []),
    'disburseNeuron' : IDL.Func([NeuronId, Account], [Result], []),
    'dissolveNeuron' : IDL.Func([NeuronId], [Result], []),
    'getCallerUser' : IDL.Func([], [UserRes], ['query']),
    'getClaimableSupply' : IDL.Func([], [IDL.Nat], ['query']),
    'getStakingAccount' : IDL.Func([Flower], [Account], ['query']),
    'getUserNeurons' : IDL.Func([IDL.Principal], [IDL.Vec(Neuron)], ['query']),
    'getUserVotingPower' : IDL.Func([IDL.Principal], [IDL.Nat], ['query']),
    'restake' : IDL.Func([NeuronId], [Result], []),
    'stake' : IDL.Func([Flower], [Result_1], []),
    'withdrawStuckFlower' : IDL.Func([Flower], [Result], []),
  });
  return Main;
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
    'trilogyBonus' : IDL.Nat,
    'rewardInterval' : Duration,
    'stakePeriod' : Duration,
    'dailyRewards' : IDL.Record({
      'btcFlower' : IDL.Nat,
      'btcFlowerGen2' : IDL.Nat,
      'icpFlower' : IDL.Nat,
      'ethFlower' : IDL.Nat,
    }),
  });
  return [IDL.Principal, InitArgs];
};
