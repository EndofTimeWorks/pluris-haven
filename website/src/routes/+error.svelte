<script lang="ts">
  import { page } from '$app/state';

  const notFound = $derived(page.status === 404);
</script>

<svelte:head>
  <title>{notFound ? 'Page not found' : 'Something went wrong'} · Pluris Haven</title>
  <meta
    name="description"
    content={notFound
      ? 'The requested Pluris Haven page could not be found.'
      : 'Pluris Haven could not load this page.'}
  />
</svelte:head>

<main id="main-content" tabindex="-1">
  <section>
    <p class="eyebrow">Error {page.status}</p>
    <h1>{notFound ? 'Page not found' : 'Something went wrong'}</h1>
    <p>
      {notFound
        ? 'That address does not match a page on this site.'
        : 'This page could not be loaded. Try again, or return to the home page.'}
    </p>
    <div class="actions">
      <a class="button primary" href="/">Return home</a>
      <a class="button" href="/support">Get support</a>
    </div>
  </section>
</main>
