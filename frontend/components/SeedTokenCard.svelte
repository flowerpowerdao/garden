<script lang="ts">
  import {onMount} from 'svelte';
  import { authStore, store } from '../store';

  import { idlFactory as idlFactorySeed, createActor } from '../../declarations/icrc1/index.js';
  import { _SERVICE as _SERVICE_SEED } from '../../declarations/icrc1/icrc1.did';

  let seed = createActor('fua74-fyaaa-aaaan-qecrq-cai');
  let circulatingSupply = 0;
  let claimableSupply = 0;

  onMount(async () => {
    circulatingSupply = Number(await seed.icrc1_total_supply()) / 1e8;
    claimableSupply = Number(await $store.gardenActor.getClaimableSupply()) / 1e8;
  });
</script>

<div class="token p-10 border-2 border-gray-950 rounded-3xl pt-0 mt-10 max-w-max dark:bg-zinc-950 dark:border-gray-400 dark:text-white">
  <div class="flex gap-4 py-8 items-center">
    <img src="../img/seed.svg" width="60" alt="SEED logo">
    <div class="text-3xl">SEED token </div>
  </div>
  <div class="flex flex-col gap-1">
    <div>Symbol: <code>SEED</code></div>
    <div>Decimals: <code>8</code></div>
    <div>Canister: <code>fua74-fyaaa-aaaan-qecrq-cai</code></div>
    <div>Standard: <code>ICRC-2</code></div>
    <div>Transfer fee: <code>0.00001 SEED</code></div>
    <div>Circulating supply: <code>{circulatingSupply.toFixed(8)}</code> SEED</div>
    <div>Claimable supply:&nbsp; <code>{claimableSupply.toFixed(8)}</code> SEED</div>
  </div>
</div>