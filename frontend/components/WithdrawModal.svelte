<script lang="ts">
  import Button from 'fpdao-ui/components/Button.svelte';
  import Modal from 'fpdao-ui/components/Modal.svelte';
  import Loader from 'fpdao-ui/components/Loader.svelte';
  import { Principal } from '@dfinity/principal';
  import { getContext } from 'svelte';

  import { authStore, store } from '../store';
  import { UserRes } from '../../declarations/main/main.did';

  export let user: UserRes;

  let refreshGarden = getContext('refreshGarden') as (target: string) => Promise<void>;

  let modalOpen = false;
  let loading = false;
  let success = false;
  let principalText = '';
  let error = '';

  let gardenerTrilogiesBonus = 0;
  let totalRewards = '0';

  function reset() {
    loading = false;
    success = false;
    error = '';
    principalText = '';
    gardenerTrilogiesBonus = 0;
    totalRewards = '0';
  }

  export function toggleModal() {
    modalOpen = !modalOpen;
    reset();
  }

  async function withdraw() {
    loading = true;

    let principal: Principal;
    try {
      principal = Principal.fromText(principalText);
    }
    catch {
      error = 'Invalid principal';
      return;
    }

    // @ts-ignore
    let res = await $store.gardenActor.claimRewards({ owner: principal, subaccount: [] });
    if ('err' in res) {
      error = res.err;
      return;
    }

    await refreshGarden('staked');

    loading = false;
    success = true;
  }

  $: {
    totalRewards = (Number(user.rewards) / 1e8).toFixed(4);

    if (modalOpen && principalText) {
      updateTotalRewards();
    }
    else {
      reset();
    }
  }

  function isValidPrincipal(principalText: string) {
    if (!principalText) {
      return false;
    }

    let principal: Principal;
    try {
      principal = Principal.fromText(principalText);
    }
    catch {
      return false;
    }
    return true;
  }

  async function updateTotalRewards() {
    if (!isValidPrincipal(principalText)) {
      return;
    }

    loading = true;

    let userRewards = Number(user.rewards) / 1e8;
    totalRewards = userRewards.toFixed(4);

    let gardenerTrilogies = await getGardenerTrilogyCount();
    gardenerTrilogiesBonus = gardenerTrilogies * 5;
    let total = userRewards + userRewards * gardenerTrilogiesBonus / 100;

    totalRewards = total.toFixed(4);

    loading = false;
  }

  async function getGardenerTrilogyCount() {
    let pineapples = await getPineapplePunks();
    if (pineapples.length == 0) {
      return 0;
    };

    let cherries = await getCherries();
    if (cherries.length == 0) {
      return 0;
    };

    let grapes = await getGrapes();
    if (grapes.length == 0) {
      return 0;
    };

    return Math.min(pineapples.length, cherries.length, grapes.length);
  }

  async function getPineapplePunks() : Promise<number[]> {
    let res = await $store.pineapplePunksActor.tokens($authStore.accountId);
    if ('ok' in res) {
      return Array.from(res.ok);
    }
    return [];
  }

  async function getCherries() : Promise<number[]> {
    let res = await $store.cherriesActor.tokens($authStore.accountId);
    if ('ok' in res) {
      return Array.from(res.ok);
    }
    return [];
  }

  async function getGrapes() : Promise<number[]> {
    let res = await $store.grapesActor.tokens($authStore.accountId);
    if ('ok' in res) {
      return Array.from(res.ok);
    }
    return [];
  }
</script>

{#if modalOpen}
  <Modal title="Withdraw SEED" {toggleModal}>
    <div class="flex gap-3 flex-col flex-1 justify-center items-center">
      {#if error}
        <div class="text-red-700 text-xl flex flex-col grow">
          <div>Error</div>
          <div>{error}</div>
        </div>
      {:else if success}
        <div class="text-xl text-green-700">
          Success!
        </div>
      {:else}
        <div class="text-xl flex flex-col gap-2 max-w-full">
          <div class="mb-5">Connected wallet principal: <b>{$authStore.principal.toText()}</b></div>

          <div>Withdraw SEED tokens to:</div>
          <input class="border-2 border-black p-2" placeholder="principal..." bind:value={principalText}>

          <div class="mt-5"><b>{gardenerTrilogiesBonus}%</b> Gardener Trilogies Bonus (5% per trilogy - Pineapple Punks, Cherries, Grapes)</div>

          {#if !isValidPrincipal(principalText)}
            <div>
              <small class="text-gray-500">enter valid principal to calculate bonus</small>
            </div>
          {/if}
        </div>
        <Button style="w-auto px-20 py-8 h-10 mt-10 rounded-[55px]" disabled={loading || !principalText} on:click={withdraw}>
          {#if loading}
            <Loader {loading}></Loader>
          {:else}
            Withdraw {totalRewards} SEED
          {/if}
        </Button>
      {/if}
    </div>
  </Modal>
{/if}