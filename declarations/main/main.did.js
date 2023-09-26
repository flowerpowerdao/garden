export const idlFactory = ({ IDL }) => {
  const Duration = IDL.Variant({
    'nanoseconds' : IDL.Nat,
    'hours' : IDL.Nat,
    'days' : IDL.Nat,
    'minutes' : IDL.Nat,
    'seconds' : IDL.Nat,
  });
  const InitArgs = IDL.Record({
    'rewardInterval' : Duration,
    'stakePeriod' : Duration,
    'dailyRewards' : IDL.Record({
      'btcFlower' : IDL.Nat,
      'icpFlower' : IDL.Nat,
      'ethFlower' : IDL.Nat,
    }),
  });
  const NeuronId = IDL.Nat;
  const Account = IDL.Record({
    'owner' : IDL.Principal,
    'subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
  });
  const Result_1 = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const Time = IDL.Int;
  const DissolveState = IDL.Variant({
    'DissolveDelay' : Time,
    'DissolveTimestamp' : Time,
  });
  const Collection = IDL.Variant({
    'BTCFlower' : IDL.Null,
    'ICPFlower' : IDL.Null,
    'ETHFlower' : IDL.Null,
  });
  const TokenIndex = IDL.Nat;
  const Flower = IDL.Record({
    'collection' : Collection,
    'tokenIndex' : TokenIndex,
  });
  const Neuron = IDL.Record({
    'id' : IDL.Nat,
    'prevRewardTime' : Time,
    'stakedAt' : Time,
    'userId' : IDL.Principal,
    'createdAt' : Time,
    'totalRewards' : IDL.Nat,
    'rewards' : IDL.Nat,
    'dissolveState' : DissolveState,
    'stakingAccount' : Account,
    'flowers' : IDL.Vec(Flower),
  });
  const Result = IDL.Variant({ 'ok' : NeuronId, 'err' : IDL.Text });
  const anon_class_10_1 = IDL.Service({
    'claimRewards' : IDL.Func([NeuronId, Account], [Result_1], []),
    'disburseNeuron' : IDL.Func([NeuronId, Account], [Result_1], []),
    'dissolveNeuron' : IDL.Func([NeuronId], [Result_1], []),
    'getCallerNeurons' : IDL.Func([], [IDL.Vec(Neuron)], ['query']),
    'getStakingAccount' : IDL.Func([IDL.Nat16], [Account], ['query']),
    'getUserNeurons' : IDL.Func([IDL.Principal], [IDL.Vec(Neuron)], ['query']),
    'getUserVotingPower' : IDL.Func([IDL.Principal], [IDL.Nat], ['query']),
    'restake' : IDL.Func([NeuronId], [Result_1], []),
    'stake' : IDL.Func([IDL.Nat16], [Result], []),
  });
  return anon_class_10_1;
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
    'rewardInterval' : Duration,
    'stakePeriod' : Duration,
    'dailyRewards' : IDL.Record({
      'btcFlower' : IDL.Nat,
      'icpFlower' : IDL.Nat,
      'ethFlower' : IDL.Nat,
    }),
  });
  return [IDL.Principal, InitArgs];
};
