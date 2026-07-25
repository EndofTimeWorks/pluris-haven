<svelte:head>
  <title>Support Pluris Haven</title>
  <meta name="description" content="Support, bug reports, and optional funding for Pluris Haven." />
</svelte:head>

<main>
  <a class="back" href="/">Back to Pluris Haven</a>
  <section>
    <p class="eyebrow">Support</p>
    <h1>Report what breaks. Support only if you want.</h1>
    <p>
      Pre-alpha feedback is most useful when it includes the version, device, source file type, and
      what screen failed. Funding links are optional and should never block core data access.
    </p>
  </section>

  <section>
    <h2>Bug reports</h2>
    <div class="cards">
      <a class="card" href="https://github.com/EndofTimeWorks/pluris-haven/issues">
        <strong>GitHub Issues</strong>
        <span>Best for import failures, crashes, broken buttons, and accessibility bugs.</span>
      </a>
      <a class="card" href="https://github.com/EndofTimeWorks/pluris-haven/releases">
        <strong>Releases</strong>
        <span>Check the newest APK and release notes before filing a duplicate.</span>
      </a>
    </div>
  </section>

  <section>
    <h2>Optional funding</h2>
    <div class="cards">
      <a class="card" href="https://github.com/sponsors/EndofTimeWorks">
        <strong>GitHub Sponsors</strong>
        <span>Recurring support through GitHub.</span>
      </a>
      <a class="card" href="https://patreon.com/EndofTimeWorks">
        <strong>Patreon</strong>
        <span>Recurring support through Patreon.</span>
      </a>
    </div>
    <p class="muted">
      Monero:
      <code
        >85xURN4NDUbULxsVcVMA8EQSLDonAYvuc945g1sQckZvXXeTXg9dLnB7tHmNqKEUFzGEkquDqCTuHS1Ca9yPCjXcNXrTvvZ</code
      >
    </p>
    <p class="muted">
      Structured metadata: <a href="/funding.json"><code>funding.json</code></a>.
    </p>
  </section>
</main>

<style>
  @import '../page.css';
</style>
