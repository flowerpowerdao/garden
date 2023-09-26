import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Account {
  'owner' : Principal,
  'subaccount' : [] | [Uint8Array | number[]],
}
export type Collection = { 'BTCFlower' : null } |
  { 'ICPFlower' : null } |
  { 'ETHFlower' : null };
export type DissolveState = { 'DissolveDelay' : Time } |
  { 'DissolveTimestamp' : Time };
export type Duration = { 'nanoseconds' : bigint } |
  { 'hours' : bigint } |
  { 'days' : bigint } |
  { 'minutes' : bigint } |
  { 'seconds' : bigint };
export interface Flower { 'collection' : Collection, 'tokenIndex' : TokenIndex }
export interface InitArgs {
  'rewardInterval' : Duration,
  'stakePeriod' : Duration,
  'dailyRewards' : {
    'btcFlower' : bigint,
    'icpFlower' : bigint,
    'ethFlower' : bigint,
  },
}
export interface Neuron {
  'id' : bigint,
  'prevRewardTime' : Time,
  'stakedAt' : Time,
  'userId' : Principal,
  'createdAt' : Time,
  'totalRewards' : bigint,
  'rewards' : bigint,
  'dissolveState' : DissolveState,
  'stakingAccount' : Account,
  'flowers' : Array<Flower>,
}
export type NeuronId = bigint;
export type Result = { 'ok' : NeuronId } |
  { 'err' : string };
export type Result_1 = { 'ok' : null } |
  { 'err' : string };
export type Time = bigint;
export type TokenIndex = bigint;
export interface anon_class_10_1 {
  'claimRewards' : ActorMethod<[NeuronId, Account], Result_1>,
  'disburseNeuron' : ActorMethod<[NeuronId, Account], Result_1>,
  'dissolveNeuron' : ActorMethod<[NeuronId], Result_1>,
  'getCallerNeurons' : ActorMethod<[], Array<Neuron>>,
  'getStakingAccount' : ActorMethod<[number], Account>,
  'getUserNeurons' : ActorMethod<[Principal], Array<Neuron>>,
  'getUserVotingPower' : ActorMethod<[Principal], bigint>,
  'restake' : ActorMethod<[NeuronId], Result_1>,
  'stake' : ActorMethod<[number], Result>,
}
export interface _SERVICE extends anon_class_10_1 {}
