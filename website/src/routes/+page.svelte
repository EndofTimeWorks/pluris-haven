<script lang="ts">
  import { mobileRelease } from '#lib/release.js';

  const status = [
    ['Version', mobileRelease.version],
    ['Android', '7 or newer'],
    ['Local data', 'Stored on your device'],
    ['Account', 'Not required'],
  ];

  const works = [
    'Members, groups, tags, custom fronts, and front history',
    'Notes, journals, messages, polls, reminders, and custom fields',
    'Imports from Simply Plural, PluralKit, Tupperbox, and PluralSpace',
    'Encrypted exports, backup snapshots, and restore rehearsals',
  ];

  const unfinished = [
    'Imports and large archives need more physical-device testing',
    'Accessibility still needs a full TalkBack and VoiceOver pass',
    'General device sync is not implemented',
    'Friends and other incomplete features remain hidden',
    'Signed iOS and TestFlight distribution are not available',
  ];
</script>

<svelte:head>
  <title>Pluris Haven</title>
  <meta
    name="description"
    content="Pluris Haven is a pre-alpha, offline-first app for systems, collectives, individuals, and anyone who finds its tools useful."
  />
</svelte:head>

<header class="site-head">
  <a class="brand" href="/" aria-current="page">Pluris Haven</a>
  <nav aria-label="Main navigation">
    <a href="/download">Download</a>
    <a href="/docs">Docs</a>
    <a href="/changelog">Changelog</a>
    <a href="/support">Support</a>
    <a href="/privacy">Privacy</a>
  </nav>
</header>

<main id="main-content" tabindex="-1">
  <section class="intro" aria-labelledby="intro-heading">
    <p class="release-state">Android pre-alpha · {mobileRelease.version}</p>
    <h1 id="intro-heading">Pluris Haven</h1>
    <p class="lede">
      An offline-first app made by systems for systems, collectives, individuals, and anyone else
      who finds its tools useful. Local use does not require an account.
    </p>
    <div class="actions">
      <a class="button primary" href={mobileRelease.universalApk.url}>
        Download Android APK <span>{mobileRelease.universalApk.size}</span>
      </a>
      <a class="button" href="/download">Installation and checksums</a>
    </div>
    <p class="caution">
      This is unfinished software. Expect bugs and keep an encrypted export of important data.
    </p>
  </section>

  <section aria-labelledby="build-heading">
    <h2 id="build-heading">Current build</h2>
    <dl class="status-list">
      {#each status as [term, detail]}
        <div>
          <dt>{term}</dt>
          <dd>{detail}</dd>
        </div>
      {/each}
    </dl>
    <p>
      The APK is signed through Google Play App Signing and published with checksums and build
      metadata. Obtainium can follow the same release file.
    </p>
    <p><a href="/obtainium">Add Pluris Haven to Obtainium</a></p>
  </section>

  <section class="two-column" aria-label="Feature status">
    <div>
      <h2>Available now</h2>
      <ul>
        {#each works as item}<li>{item}</li>{/each}
      </ul>
    </div>
    <div>
      <h2>Not finished</h2>
      <ul>
        {#each unfinished as item}<li>{item}</li>{/each}
      </ul>
    </div>
  </section>

  <section aria-labelledby="privacy-heading">
    <h2 id="privacy-heading">Private by default</h2>
    <p>
      Core tracking, writing, imports, and exports work locally. Private text is encrypted on the
      device, and portable backups use authenticated encryption. Online features must explain what
      leaves the device before they run.
    </p>
    <p><a href="/privacy">Read the privacy notes and current limits</a></p>
  </section>

  <section aria-labelledby="accessibility-heading">
    <h2 id="accessibility-heading">Accessibility</h2>
    <p>
      The app includes large-text, contrast, reduced-motion, and screen-reader support. Automated
      checks do not replace testing with TalkBack, VoiceOver, keyboards, switches, and physical
      devices; that work is still in progress.
    </p>
  </section>
</main>

<footer>
  <span>plurishaven.app</span>
  <nav aria-label="Footer navigation">
    <a href="https://github.com/EndofTimeWorks/pluris-haven">Source</a>
    <a href="https://github.com/EndofTimeWorks/pluris-haven/issues">Issues</a>
    <a href="/distribution">Distribution</a>
    <a href="/terms">Terms</a>
  </nav>
</footer>

<style>
  :global(*) {
    box-sizing: border-box;
  }

  :global(body) {
    margin: 0;
    background: var(--page-bg);
    color: var(--text);
    font-family:
      ui-sans-serif,
      system-ui,
      -apple-system,
      BlinkMacSystemFont,
      'Segoe UI',
      sans-serif;
    text-size-adjust: 100%;
  }

  :global(a) {
    color: var(--link);
    text-underline-offset: 0.18em;
  }

  .site-head,
  main,
  footer {
    width: min(100% - 36px, 980px);
    margin-inline: auto;
  }

  .site-head,
  footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 24px;
    padding-block: 22px;
  }

  .site-head {
    border-bottom: 1px solid var(--border);
  }

  .brand {
    color: var(--text);
    font-size: 1.05rem;
    font-weight: 750;
    text-decoration: none;
  }

  nav {
    display: flex;
    flex-wrap: wrap;
    gap: 10px 18px;
  }

  nav a {
    color: var(--body-text);
  }

  main {
    min-height: 70vh;
  }

  section {
    max-width: 760px;
    padding-block: 42px;
  }

  section + section {
    border-top: 1px solid var(--border);
  }

  .intro {
    padding-block: clamp(48px, 7vw, 72px) 48px;
  }

  .release-state,
  .caution {
    color: var(--muted-text);
    font-size: 0.92rem;
  }

  h1,
  h2,
  p {
    margin-top: 0;
  }

  h1 {
    max-width: none;
    margin-bottom: 20px;
    font-size: clamp(2.5rem, 6vw, 3.6rem);
    line-height: 1.05;
    letter-spacing: -0.025em;
  }

  h2 {
    margin-bottom: 14px;
    font-size: 1.35rem;
  }

  p,
  li,
  dd {
    color: var(--body-text);
    line-height: 1.65;
  }

  .lede {
    max-width: 62ch;
    font-size: 1.1rem;
  }

  .actions {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin-block: 28px 18px;
  }

  .button {
    display: inline-flex;
    min-height: 48px;
    align-items: center;
    justify-content: center;
    border: 1px solid var(--button-border);
    border-radius: 6px;
    padding: 0 16px;
    color: var(--text);
    font-weight: 700;
    text-decoration: none;
  }

  .button.primary {
    border-color: var(--primary-border);
    background: var(--primary-bg);
    color: var(--primary-text);
  }

  .button:hover,
  .button:focus-visible {
    border-color: var(--button-hover-border);
  }

  .button span {
    margin-left: 8px;
    color: var(--button-subtext);
    font-size: 0.86rem;
  }

  .status-list {
    margin: 0 0 24px;
  }

  .status-list div {
    display: grid;
    grid-template-columns: minmax(100px, 0.35fr) 1fr;
    gap: 20px;
    border-bottom: 1px solid var(--border);
    padding-block: 10px;
  }

  .status-list dt {
    color: var(--muted-text);
  }

  .status-list dd {
    margin: 0;
    color: var(--text);
  }

  .two-column {
    display: grid;
    max-width: none;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: clamp(32px, 7vw, 72px);
  }

  ul {
    margin: 0;
    padding-left: 1.25rem;
  }

  li + li {
    margin-top: 9px;
  }

  footer {
    border-top: 1px solid var(--border);
    color: var(--muted-text);
    font-size: 0.9rem;
  }

  @media (max-width: 680px) {
    .site-head,
    footer {
      align-items: flex-start;
      flex-direction: column;
    }

    .two-column {
      grid-template-columns: 1fr;
    }

    .button {
      width: 100%;
    }
  }

  @media (forced-colors: active) {
    .button {
      border: 1px solid ButtonText;
    }
  }
</style>
