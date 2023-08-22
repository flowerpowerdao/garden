<script lang="ts">
  import { getTokenName, getCollectionCanisterId, tokenIdentifier } from '../utils';

  export let collection: 'btcFlower' | 'ethFlower' | 'icpFlower';
  export let tokenIndex: number;

  let collectionCanisterId = getCollectionCanisterId(collection);
  let previewUrl = '';
  if (collection === 'btcFlower') {
    previewUrl = `https://${collectionCanisterId}.raw.icp0.io/${tokenIndex}?type=thumbnail`;
  } else if (collection === 'ethFlower') {
    previewUrl = `https://${collectionCanisterId}.raw.icp0.io/?tokenid=${tokenIdentifier(collectionCanisterId, tokenIndex)}&type=thumbnail`;
  } else if (collection === 'icpFlower') {
    previewUrl = `https://${collectionCanisterId}.raw.icp0.io/?tokenid=${tokenIdentifier(collectionCanisterId, tokenIndex)}`;
  }
</script>

<div class="flex flex-col items-center bg-gray-200 border-black dark:bg-zinc-950 dark:text-white dark:border-white rounded-lg overflow-hidden border-2 box-border">
  <iframe src="{previewUrl}" title=""></iframe>
  <div class="px-3 py-4">
    <div class="pb-2">{getTokenName(collection, tokenIndex)}</div>
    <slot></slot>
  </div>
</div>

<style>
  iframe {
    width: 198px;
    height: 280px;
  }
</style>