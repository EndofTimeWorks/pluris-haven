<script lang="ts">
  import favicon from '$lib/assets/favicon.svg';

  let { children } = $props();
</script>

<svelte:head>
  <link rel="icon" href={favicon} />
</svelte:head>

<a class="skip-link" href="#main-content">Skip to content</a>

<div>
  {@render children()}
</div>

<style>
  .skip-link {
    position: fixed;
    top: -100%;
    left: 12px;
    z-index: 999;
    border: 3px solid #f0ca63;
    border-radius: 8px;
    padding: 10px 20px;
    background: #151820;
    color: #f0ca63;
    font-weight: 800;
    text-decoration: none;
  }

  .skip-link:focus {
    top: 12px;
  }

  :global(:focus-visible) {
    outline: 3px solid #f0ca63;
    outline-offset: 2px;
  }

  :global(html) {
    color-scheme: dark;
  }

  @media (prefers-reduced-motion: reduce) {
    :global(*),
    :global(*::before),
    :global(*::after) {
      animation-duration: 0.01ms !important;
      transition-duration: 0.01ms !important;
    }
  }
</style>
