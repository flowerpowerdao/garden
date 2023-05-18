import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type AccountIdentifier = string;
export type Duration = { 'nanoseconds' : bigint } |
  { 'hours' : bigint } |
  { 'days' : bigint } |
  { 'minutes' : bigint } |
  { 'seconds' : bigint };
export interface InitArgs {
  'minStakePeriod' : Duration,
  'seedRewardPerHour' : bigint,
}
export interface anon_class_5_1 {
  'getStakingAccountId' : ActorMethod<[Principal], AccountIdentifier>,
}
export interface _SERVICE extends anon_class_5_1 {}
