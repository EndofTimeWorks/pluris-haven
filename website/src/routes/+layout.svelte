<script lang="ts">
  import { onMount } from 'svelte';
  import favicon from '#lib/assets/favicon.svg';

  let { children } = $props();
  let theme = $state('system');

  onMount(() => {
    try {
      const saved = localStorage.getItem('pluris-theme');
      if (saved === 'light' || saved === 'dark') theme = saved;
    } catch {
      // The system preference still works when storage is unavailable.
    }
    applyTheme();
  });

  function applyTheme() {
    if (theme === 'system') {
      delete document.documentElement.dataset.theme;
    } else {
      document.documentElement.dataset.theme = theme;
    }
    try {
      if (theme === 'system') localStorage.removeItem('pluris-theme');
      else localStorage.setItem('pluris-theme', theme);
    } catch {
      // Keep the choice active for this page even when storage is unavailable.
    }
  }
</script>

<svelte:head>
  <link rel="icon" href={favicon} />
</svelte:head>

<a class="skip-link" href="#main-content">Skip to content</a>
<div class="theme-control">
  <label for="site-theme">Theme</label>
  <select id="site-theme" bind:value={theme} onchange={applyTheme}>
    <option value="system">System</option>
    <option value="light">Light</option>
    <option value="dark">Dark</option>
  </select>
</div>

<div>
  {@render children()}
</div>

<style>
  .theme-control {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: 8px;
    padding: 8px 16px;
    background: var(--page-bg);
    color: var(--body-text);
    font:
      0.9rem ui-sans-serif,
      system-ui,
      sans-serif;
  }

  .theme-control select {
    min-height: 36px;
    border: 1px solid var(--button-border);
    border-radius: 6px;
    padding: 4px 8px;
    background: var(--page-bg);
    color: var(--text);
    font: inherit;
  }

  .skip-link {
    position: fixed;
    top: -100%;
    left: 12px;
    z-index: 999;
    border: 3px solid var(--focus);
    border-radius: 8px;
    padding: 10px 20px;
    background: var(--page-bg);
    color: var(--focus);
    font-weight: 800;
    text-decoration: none;
  }

  .skip-link:focus {
    top: 12px;
  }

  :global(:focus-visible) {
    outline: 3px solid var(--focus);
    outline-offset: 2px;
  }

  :global(html) {
    color-scheme: dark;
    --page-bg: #151820;
    --text: #f4f0ff;
    --body-text: #c9c4d4;
    --muted-text: #aaa4b5;
    --link: #d5ccff;
    --border: #343846;
    --button-border: #565b6d;
    --primary-border: #7863ff;
    --primary-bg: #5940db;
    --primary-text: #ffffff;
    --button-hover-border: #a99aff;
    --button-subtext: #ebe7ff;
    --code-bg: #222631;
    --pre-border: #3a3f50;
    --pre-bg: #10131a;
    --focus: #f0ca63;
  }

  @media (prefers-color-scheme: light) {
    :global(html:not([data-theme='dark'])) {
      color-scheme: light;
      --page-bg: #f7f7fc;
      --text: #1b1d27;
      --body-text: #44495a;
      --muted-text: #626777;
      --link: #4330a9;
      --border: #c8cada;
      --button-border: #777b8d;
      --primary-border: #5940db;
      --primary-bg: #5940db;
      --primary-text: #ffffff;
      --button-hover-border: #4330a9;
      --button-subtext: #ffffff;
      --code-bg: #e9eaf1;
      --pre-border: #aeb3c3;
      --pre-bg: #f0f1f7;
      --focus: #895f00;
    }
  }

  :global(html[data-theme='light']) {
    color-scheme: light;
    --page-bg: #f7f7fc;
    --text: #1b1d27;
    --body-text: #44495a;
    --muted-text: #626777;
    --link: #4330a9;
    --border: #c8cada;
    --button-border: #777b8d;
    --primary-border: #5940db;
    --primary-bg: #5940db;
    --primary-text: #ffffff;
    --button-hover-border: #4330a9;
    --button-subtext: #ffffff;
    --code-bg: #e9eaf1;
    --pre-border: #aeb3c3;
    --pre-bg: #f0f1f7;
    --focus: #895f00;
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
