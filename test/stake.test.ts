import { describe, test, expect } from 'vitest';
import { execSync } from 'child_process';
import { User } from './user';

describe('staking', () => {
  test('deploy', async () => {
    execSync('npm run deploy:main');
  });

  test('should return same staking account for the same nonce', async () => {
    let user = new User;
    let stakingAccount1 = await user.mainActor.getStakingAccount(23);
    let stakingAccount2 = await user.mainActor.getStakingAccount(23);
    expect(stakingAccount1).toEqual(stakingAccount2);
  });

  test('obtain unique staking accounts for random nonce', async () => {
    let user = new User;
    let set = new Set;
    for (let i = 0; i < 10; i++) {
      let stakingAccount = await user.mainActor.getStakingAccount((Math.random() * (2 ** 16 - 1)) |0);
      set.add(stakingAccount);
    }
    expect(set.size).toBe(10);
  });

  test('stake', async () => {
    let user = new User;
    let stakingAccount = await user.mainActor.getStakingAccount(1);
  });
});