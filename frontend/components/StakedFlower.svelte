<script lang="ts">
  import { formatDistanceToNowStrict } from 'date-fns';
  import Button from 'fpdao-ui/components/Button.svelte';

  import FlowerPreview from './FlowerPreview.svelte';
  import DissolveModal from './DissolveModal.svelte';
  import RestakeModal from './RestakeModal.svelte';
  import DisburseModal from './DisburseModal.svelte';
  import { getCollectionDailyRewards, getNeuronCollection, getNeuronTokenIndex } from '../utils';
  import { Neuron } from '../../declarations/main/main.did';

  export let neuron: Neuron;

  let collection = getNeuronCollection(neuron);
  let tokenIndex = getNeuronTokenIndex(neuron);

  let dissolveModal: DissolveModal;
  let restakeModal: RestakeModal;
  let disburseModal: DisburseModal;

  let toggleDissolveModal = () => {
    dissolveModal.toggleModal();
  };

  let toggleRestakeModal = () => {
    restakeModal.toggleModal();
  };

  let toggleDisburseModal = () => {
    disburseModal.toggleModal();
  };

  let state = 'staked';
  $: {
    if ('DissolveTimestamp' in neuron.dissolveState) {
      if (neuron.dissolveState.DissolveTimestamp / 1_000_000n > BigInt(Date.now())) {
        state = 'dissolving';
      } else {
        state = 'dissolved';
      }
    }
    else {
      state = 'staked';
    }
  }

  let status = '';
  $: {
    if (state === 'staked') {
      status = 'Planted';
    } else if (state === 'dissolving' && 'DissolveTimestamp' in neuron.dissolveState) {
      status = `Extracting: ${formatDistanceToNowStrict(new Date(Number(neuron.dissolveState.DissolveTimestamp / 1_000_000n)))} left`;
    } else if (state === 'dissolved') {
      status = 'Extracted';
    }
  }
</script>

<FlowerPreview {collection} {tokenIndex}>
  <div class="flex flex-col gap-2">
    <div class="mb-1"></div>

    <div class="-mr-2">{status}</div>
    {#if state === 'staked'}
      <div>Produces: <span class="font-bold">{getCollectionDailyRewards(getNeuronCollection(neuron))}</span> SEED/day</div>
    {/if}

    <div class="mb-2"></div>

    <div class="w-40 m-auto flex flex-col gap-3">
      {#if state === 'staked'}
        <Button on:click={toggleDissolveModal}>Extract</Button>
      {:else if state === 'dissolving'}
        <Button on:click={toggleRestakeModal}>Replant</Button>
      {:else if state === 'dissolved'}
        <Button on:click={toggleRestakeModal}>Replant</Button>
        <Button on:click={toggleDisburseModal}>Withdraw</Button>
      {/if}
    </div>
  </div>
</FlowerPreview>

<DissolveModal {neuron} bind:this={dissolveModal}></DissolveModal>
<RestakeModal {neuron} bind:this={restakeModal}></RestakeModal>
<DisburseModal {neuron} {collection} bind:this={disburseModal}></DisburseModal>