<script lang="ts">
  import { getTokenName, getCollectionCanisterId, tokenIdentifier } from '../utils';
  import { Collection } from '../types';

  export let collection: Collection;
  export let tokenIndex: number;
  export let status: string = '';

  $: collectionCanisterId = getCollectionCanisterId(collection);

  let previewUrl = '';
  $: {
    if (collection === 'btcFlower') {
      previewUrl = `https://${collectionCanisterId}.raw.icp0.io/${tokenIndex}?type=thumbnail`;
    } else if (collection === 'ethFlower') {
      previewUrl = `https://${collectionCanisterId}.raw.icp0.io/?tokenid=${tokenIdentifier(collectionCanisterId, tokenIndex)}&type=thumbnail`;
    } else if (collection === 'icpFlower') {
      previewUrl = `https://${collectionCanisterId}.raw.icp0.io/?tokenid=${tokenIdentifier(collectionCanisterId, tokenIndex)}`;
    } else if (collection === 'btcFlowerGen2') {
      previewUrl = `https://${collectionCanisterId}.raw.icp0.io/?tokenid=${tokenIdentifier(collectionCanisterId, tokenIndex)}`;
    }
  };
</script>

<div class="preview relative flex flex-col items-center bg-gray-200 border-black dark:bg-zinc-950 dark:text-white dark:border-white rounded-lg overflow-hidden border-2 box-border">
  <iframe src="{previewUrl}" title=""></iframe>
  <div class="px-3 py-4 flex flex-col items-center">
    <div class="pb-2 text-center">{getTokenName(collection, tokenIndex)}</div>
    <slot></slot>
  </div>
  {#if status}
    <div class="status absolute left-0 rounded-br-md p-1  bg-gray-100 text-black">{status}</div>
  {/if}
</div>

<style>
  iframe {
    width: 220px;
    height: 311px;
  }

  .preview * {
    margin: 0 -4px;
  }
</style>