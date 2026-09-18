<script lang="ts">
  import { onMount } from 'svelte';

  import { obtainiumRedirectUrl } from '$lib/obtainium-config';

  onMount(() => window.location.replace(obtainiumRedirectUrl));
</script>

<svelte:head>
  <title>Open Pluris Haven in Obtainium</title>
</svelte:head>

<main id="main-content" tabindex="-1">
  <p>Opening Pluris Haven in Obtainium…</p>
  <p><a href={obtainiumRedirectUrl}>Continue to Obtainium</a></p>
</main>
