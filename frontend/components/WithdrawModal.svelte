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

  function reset() {
    loading = false;
    success = false;
    error = '';
    principalText = '';
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

    let res = await $store.gardenActor.claimRewards({ owner: principal, subaccount: [] });
    if ('err' in res) {
      error = res.err;
      return;
    }

    await refreshGarden('staked');

    loading = false;
    success = true;
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
        </div>
        <Button style="w-auto px-20 py-8 h-10 mt-10 rounded-[55px]" disabled={loading || !principalText} on:click={withdraw}>
          {#if loading}
            <Loader {loading}></Loader>
          {:else}
            Withdraw {(Number(user.rewards) / 1e8).toFixed(4)} SEED
          {/if}
        </Button>
      {/if}
    </div>
  </Modal>
{/if}