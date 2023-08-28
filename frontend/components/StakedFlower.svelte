<script lang="ts">
  import Button from 'fpdao-ui/components/Button.svelte';
  import Modal from 'fpdao-ui/components/Modal.svelte';
  import Loader from 'fpdao-ui/components/Loader.svelte';
  import { getContext } from 'svelte';
  import { formatDistanceToNow, formatDistanceToNowStrict } from 'date-fns';

  import FlowerPreview from './FlowerPreview.svelte';
  import { store } from '../store';
  import { Neuron } from 'declarations/main/main.did';

  export let collection: 'btcFlower' | 'ethFlower' | 'icpFlower';
  export let tokenIndex: number;
  export let neuron: Neuron;

  let refreshGarden = getContext('refreshGarden') as () => Promise<void>;

  let loading = false;
  let success = false;
  let dissolveModalOpen = false;
  let error = '';

  function toggleDissolveModal() {
    dissolveModalOpen = !dissolveModalOpen;
    loading = false;
    error = '';
  }

  async function startDissolve() {
    loading = true;

    let stakeRes = await $store.gardenActor.dissolveNeuron(neuron.id);
    if ('err' in stakeRes) {
      error = stakeRes.err;
      return;
    }

    await refreshGarden();

    loading = false;
    dissolveModalOpen = false;
  }

  let state = 'staked';
  if ('DissolveTimestamp' in neuron.dissolveState) {
    if (neuron.dissolveState.DissolveTimestamp / 1_000_000n > BigInt(Date.now())) {
      state = 'dissolving';
    } else {
      state = 'dissolved';
    }
  }

  let status = '';
  $: if (state === 'staked') {
    status = 'Not Dissolving';
  } else if (state === 'dissolving' && 'DissolveTimestamp' in neuron.dissolveState) {
    status = `Dissolving: ${formatDistanceToNowStrict(new Date(Number(neuron.dissolveState.DissolveTimestamp / 1_000_000n)))} left`;
  } else if (state === 'dissolved') {
    status = 'Dissolved';
  }
</script>

<FlowerPreview {collection} {tokenIndex}>
  <div class="flex flex-col gap-2">
    <div>{status}</div>
    <div>Balance: <span class="font-bold">{(Number(neuron.rewards) / 1e8).toFixed(3)}</span> SEED</div>

    <div class="mb-1"></div>

    {#if state === 'staked'}
      <Button on:click={toggleDissolveModal}>Dissolve</Button>
    {:else if state === 'dissolving'}
      <Button on:click={toggleDissolveModal}>Restake</Button>
    {:else if state === 'dissolved'}
      <Button on:click={toggleDissolveModal} disabled={state !== 'dissolved'}>Disburse</Button>
    {/if}
    <Button on:click={toggleDissolveModal}>Withdraw</Button>
  </div>
</FlowerPreview>

{#if dissolveModalOpen}
  <Modal title="Dissolve" toggleModal={toggleDissolveModal}>
    <div class="flex gap-3 flex-col flex-1 justify-center items-center">
      {#if error}
        <div class="text-red-700 text-xl flex flex-col grow">
          <div>Error</div>
          <div>{error}</div>
        </div>
      {:else if success}
        <div class="text-xl flex flex-col gap-4">
        </div>
      {:else}
        <div class="text-xl flex flex-col gap-4">
          <div>Dissolve delay is 30 days.</div>
          <div>After 30 days you can disburse neuron and withdraw flowers.</div>
        </div>
        <Button style="w-auto px-20 py-8 h-10 mt-10 rounded-[55px]" disabled={loading} on:click={startDissolve}>
          {#if loading}
            <Loader {loading}></Loader>
          {:else}
            Start Dissolve
          {/if}
        </Button>
      {/if}
    </div>
  </Modal>
{/if}