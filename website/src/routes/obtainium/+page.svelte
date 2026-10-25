<script lang="ts">
  import { obtainiumRedirectUrl, repositoryUrl } from '#lib/obtainium-config.js';
</script>

<svelte:head>
  <title>Open Pluris Haven in Obtainium</title>
</svelte:head>

<main id="main-content" tabindex="-1">
  <a class="back" href="/download">Back to downloads</a>
  <section>
    <h1>Open Pluris Haven in Obtainium</h1>
    <p>
      Continue to an external Obtainium-hosted redirect page to add the Pluris Haven GitHub release
      source. That page may load analytics, advertising and external fonts.
    </p>
    <div class="actions">
      <a class="button primary" href={obtainiumRedirectUrl}>Continue to Obtainium</a>
      <a class="button" href="/download">Stay on Pluris Haven</a>
    </div>
    <p class="muted">
      You can also add <code>{repositoryUrl}</code> as a GitHub source directly in Obtainium.
    </p>
  </section>
</main>

<style>
  @import '../page.css';
</style>
