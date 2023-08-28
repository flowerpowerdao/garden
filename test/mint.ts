import { User } from './user';

let minter = new User('minter');

(async () => {
  await minter.mintBTCFlower(process.env.WALLET_ADDRESS);
  await minter.mintETHFlower(process.env.WALLET_ADDRESS);
  await minter.mintICPFlower(process.env.WALLET_ADDRESS);
})();