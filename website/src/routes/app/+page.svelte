<script lang="ts">
  const blockers = [
    'Shared import/export code between Android and browser builds',
    'Encrypted local browser storage with clear backup and restore flows',
    'Large Simply Plural imports tested without tab crashes or duplicate jobs',
    'Keyboard, screen reader, and reduced-motion checks on desktop and mobile browsers',
  ];

  const next = [
    ['Use the app today', '/download'],
    ['Read the changelog', '/changelog'],
    ['Check distribution notes', '/distribution'],
  ];
</script>

<svelte:head>
  <title>Pluris Haven Web App</title>
  <meta name="description" content="Current Pluris Haven web app status and browser client plan." />
</svelte:head>

<main id="main-content" tabindex="-1">
  <a class="back" href="/">Back to Pluris Haven</a>
  <section>
    <p class="eyebrow">Web UI</p>
    <h1>Browser app is not open yet.</h1>
    <p>
      Pluris Haven is Android-first right now. The browser client should use the same local-first
      data model, not a fake account screen or a separate half-compatible import path.
    </p>
  </section>

  <section>
    <h2>Before this opens</h2>
    <ul>
      {#each blockers as blocker}
        <li>{blocker}</li>
      {/each}
    </ul>
  </section>

  <section>
    <h2>Expected shape</h2>
    <p>
      The first useful web build should install as a PWA, import and export without an account, keep
      data local by default, and connect to optional sync only after the offline archive format is
      solid.
    </p>
  </section>

  <section>
    <h2>For now</h2>
    <div class="cards">
      {#each next as [label, href]}
        <a class="card" {href}>
          <strong>{label}</strong>
          <span>Open the current public path.</span>
        </a>
      {/each}
    </div>
  </section>
</main>

<style>
  @import '../page.css';
</style>
