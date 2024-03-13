import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface Account {
  'owner' : Principal,
  'subaccount' : [] | [Uint8Array | number[]],
}
export type Collection = { 'BTCFlowerGen2' : null } |
  { 'BTCFlower' : null } |
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
  'trilogyBonus' : bigint,
  'rewardInterval' : Duration,
  'stakePeriod' : Duration,
  'dailyRewards' : {
    'btcFlower' : bigint,
    'btcFlowerGen2' : bigint,
    'icpFlower' : bigint,
    'ethFlower' : bigint,
  },
}
export interface Main {
  'claimRewards' : ActorMethod<[Account], Result>,
  'disburseNeuron' : ActorMethod<[NeuronId, Account], Result>,
  'dissolveNeuron' : ActorMethod<[NeuronId], Result>,
  'getCallerUser' : ActorMethod<[], UserRes>,
  'getClaimableSupply' : ActorMethod<[], bigint>,
  'getStakingAccount' : ActorMethod<[Flower], Account>,
  'getUserNeurons' : ActorMethod<[Principal], Array<Neuron>>,
  'getUserVotingPower' : ActorMethod<[Principal], bigint>,
  'restake' : ActorMethod<[NeuronId], Result>,
  'stake' : ActorMethod<[Flower], Result_1>,
  'withdrawStuckFlower' : ActorMethod<[Flower], Result>,
}
export interface Neuron {
  'id' : bigint,
  'prevRewardTime' : Time,
  'stakedAt' : Time,
  'flower' : Flower,
  'userId' : Principal,
  'createdAt' : Time,
  'totalRewards' : bigint,
  'dissolveState' : DissolveState,
  'stakingAccount' : Account,
}
export type NeuronId = bigint;
export type Result = { 'ok' : null } |
  { 'err' : string };
export type Result_1 = { 'ok' : NeuronId } |
  { 'err' : string };
export type Time = bigint;
export type TokenIndex = bigint;
export interface UserRes {
  'id' : Principal,
  'createdAt' : Time,
  'totalRewards' : bigint,
  'rewards' : bigint,
  'neurons' : Array<Neuron>,
}
export interface _SERVICE extends Main {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: ({ IDL }: { IDL: IDL }) => IDL.Type[];
