import { describe, test, expect } from 'vitest';
import { execSync } from 'child_process';
import { User } from './user';

describe('staking', () => {
  test('deploy', async () => {
    execSync('npm run deploy:main');
  });

  test('stake', async () => {
    console.log(new User().accountId);
    console.log(new User().accountId);
  });
});