<script lang="ts">
  import { formatDistanceToNowStrict } from 'date-fns';
  import Button from 'fpdao-ui/components/Button.svelte';

  import FlowerPreview from './FlowerPreview.svelte';
  import DissolveModal from './DissolveModal.svelte';
  import RestakeModal from './RestakeModal.svelte';
  import WithdrawModal from './WithdrawModal.svelte';
  import DisburseModal from './DisburseModal.svelte';
  import { getNeuronCollection, getNeuronTokenIndex } from '../utils';
  import { Neuron } from '../../declarations/main/main.did';

  export let neuron: Neuron;

  let collection = getNeuronCollection(neuron);
  let tokenIndex = getNeuronTokenIndex(neuron);

  let dissolveModal: DissolveModal;
  let restakeModal: RestakeModal;
  let withdrawModal: WithdrawModal;
  let disburseModal: DisburseModal;

  let toggleDissolveModal = () => {
    dissolveModal.toggleModal();
  };

  let toggleRestakeModal = () => {
    restakeModal.toggleModal();
  };

  let toggleWithdrawModal = () => {
    withdrawModal.toggleModal();
  };

  let toggleDisburseModal = () => {
    disburseModal.toggleModal();
  };

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
    <div class="mb-1"></div>

    <div>{status}</div>
    <div>Balance: <span class="font-bold">{(Number(neuron.rewards) / 1e8).toFixed(3)}</span> SEED</div>

    <div class="mb-2"></div>

    <Button on:click={toggleWithdrawModal}>Withdraw</Button>
    {#if state === 'staked'}
      <Button on:click={toggleDissolveModal}>Dissolve</Button>
    {:else if state === 'dissolving'}
      <Button on:click={toggleRestakeModal}>Restake</Button>
    {:else if state === 'dissolved'}
      <Button on:click={toggleDisburseModal}>Disburse</Button>
    {/if}
  </div>
</FlowerPreview>

<DissolveModal {neuron} {collection} bind:this={dissolveModal}></DissolveModal>
<RestakeModal {neuron} bind:this={restakeModal}></RestakeModal>
<WithdrawModal {neuron} {collection} bind:this={withdrawModal}></WithdrawModal>
<DisburseModal {neuron} {collection} bind:this={disburseModal}></DisburseModal>