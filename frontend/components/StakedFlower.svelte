<script lang="ts">
  import Button from 'fpdao-ui/components/Button.svelte';
  import { formatDistanceToNowStrict } from 'date-fns';

  import FlowerPreview from './FlowerPreview.svelte';
  import { Neuron } from 'declarations/main/main.did';
  import DissolveModal from './DissolveModal.svelte';
  import WithdrawModal from './WithdrawModal.svelte';
  import DisburseModal from './DisburseModal.svelte';

  export let collection: 'btcFlower' | 'ethFlower' | 'icpFlower';
  export let tokenIndex: number;
  export let neuron: Neuron;

  let dissolveModal: DissolveModal;
  let withdrawModal: WithdrawModal;
  let disburseModal: DisburseModal;

  let toggleDissolveModal = () => {
    dissolveModal.toggleModal();
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
      <Button on:click={toggleDissolveModal}>Restake</Button>
    {:else if state === 'dissolved'}
      <Button on:click={toggleDisburseModal}>Disburse</Button>
    {/if}
  </div>
</FlowerPreview>

<DissolveModal {neuron} {collection} bind:this={dissolveModal}></DissolveModal>
<WithdrawModal {neuron} {collection} bind:this={withdrawModal}></WithdrawModal>
<DisburseModal {neuron} {collection} bind:this={disburseModal}></DisburseModal>