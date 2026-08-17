<script lang="ts">
  import { mobileRelease } from '$lib/release';

  const status = [
    ['Release', mobileRelease.version],
    ['Platform', 'Android 7 or newer'],
    ['Storage', 'On-device by default'],
    ['Account', 'Not required for local use'],
  ];

  const works = [
    'Members, archived members, groups, and custom fronts',
    'Front history, current front, and status notes',
    'Notes, messages, polls, reminders, and custom fields',
    'Simply Plural, PluralKit, Tupperbox, and PluralSpace imports',
    'Encrypted exports, backup snapshots, and restore rehearsals',
  ];

  const rough = [
    'SP-style co-fronting still needs to behave closer to independent front entries',
    'Import details need clearer counts, skips, and per-row errors',
    'Avatars and large archives need more physical-device testing',
    'Encrypted Prism imports are detected but not implemented yet',
    'Accessibility needs a full TalkBack and VoiceOver pass',
  ];

  const privacy = [
    ['Local-first', 'Core tracking, writing, and imports work without an account.'],
    ['Encrypted', 'Private local content and portable backups use authenticated encryption.'],
    ['Portable', 'Export your data and rehearse a restore before relying on a backup.'],
  ];

  const previewTiles = [
    'Members',
    'Front history',
    'Custom fronts',
    'Groups',
    'Notes',
    'Import / export',
  ];
</script>

<svelte:head>
  <title>Pluris Haven</title>
  <meta
    name="description"
    content="Download Pluris Haven, a pre-alpha offline-first app made by systems for systems, collectives, individuals, and anyone who finds it useful."
  />
</svelte:head>

<main id="main-content" tabindex="-1">
  <header class="site-head">
    <a class="brand" href="/" aria-current="page">
      <span class="mark" aria-hidden="true">PH</span>
      <span>Pluris Haven</span>
    </a>
    <nav aria-label="Main navigation">
      <a href="/download">Download</a>
      <a href="/docs">Docs</a>
      <a href="/changelog">Changelog</a>
      <a href="/distribution">Distribution</a>
      <a href="/support">Support</a>
      <a href="/privacy">Privacy</a>
      <a href="/app">Web app</a>
    </nav>
  </header>

  <section class="intro" aria-labelledby="intro-heading">
    <div class="intro-copy">
      <p class="label">Android pre-alpha</p>
      <h1 id="intro-heading">Offline-first, without assumptions about who you are.</h1>
      <p class="lede">
        Made by systems. Welcoming systems, collectives, individuals, and anyone who finds the tools
        useful. No account is required for local use, and your data stays on your device by default.
      </p>
      <div class="actions">
        <a class="button primary" href={mobileRelease.universalApk.url}>
          Download signed Android APK <span>{mobileRelease.universalApk.size}</span>
        </a>
        <a class="button" href="/download">Install and verify</a>
      </div>
      <p class="release-note">
        Pre-alpha {mobileRelease.version}. Expect bugs and keep an encrypted export of data you care
        about.
      </p>
    </div>

    <figure>
      <div class="app-preview" aria-hidden="true">
        <div class="phone-status"><span>8:32</span><span>87%</span></div>
        <div class="app-card header-card">
          <div><strong>Pluris Haven</strong><span>saved on device</span></div>
          <b>pre-alpha</b>
        </div>
        <div class="app-card front-card"><span>Currently fronting</span><strong>None</strong></div>
        <div class="tile-grid">
          {#each previewTiles as tile}
            <div>{tile}</div>
          {/each}
        </div>
      </div>
      <figcaption>An illustrated preview of the current mobile dashboard.</figcaption>
    </figure>
  </section>

  <dl class="status-strip" aria-label="Current project status">
    {#each status as [term, detail]}
      <div>
        <dt>{term}</dt>
        <dd>{detail}</dd>
      </div>
    {/each}
  </dl>

  <section class="download-callout" aria-labelledby="get-build-heading">
    <div>
      <p class="label">Try the actual app</p>
      <h2 id="get-build-heading">One file, no store account.</h2>
      <p>
        The universal APK works on supported Android phones. It is release-mode, signed, and
        published with a SHA-256 checksum and build record.
      </p>
    </div>
    <div class="actions">
      <a class="button primary" href={mobileRelease.universalApk.url}>
        Download APK <span>{mobileRelease.universalApk.size}</span>
      </a>
      <a class="button" href={mobileRelease.releaseUrl}>Release notes and files</a>
    </div>
  </section>

  <section class="split" aria-label="Current feature status">
    <div>
      <h2>Works now</h2>
      <ul>
        {#each works as item}<li>{item}</li>{/each}
      </ul>
    </div>
    <div>
      <h2>Still rough</h2>
      <ul>
        {#each rough as item}<li>{item}</li>{/each}
      </ul>
    </div>
  </section>

  <section class="notes">
    <div>
      <h2>Why it exists</h2>
      <p>
        Pluris Haven is a practical replacement path for anyone who needs their data without
        depending on another operator's hosted app. Its words and features should adapt to an
        entity, not force an identity or experience onto them.
      </p>
    </div>
    <div>
      <h2>Accessibility is part of the work</h2>
      <p>
        The app includes large-text, contrast, reduced-motion, and screen-reader support. It still
        needs full TalkBack and VoiceOver testing on physical devices, and that limitation is kept
        visible instead of being called finished.
      </p>
    </div>
  </section>

  <section class="privacy" aria-labelledby="privacy-heading">
    <div>
      <p class="label">Designed around sensitive data</p>
      <h2 id="privacy-heading">Useful without giving up control.</h2>
    </div>
    <div class="privacy-grid">
      {#each privacy as [title, detail]}
        <article>
          <h3>{title}</h3>
          <p>{detail}</p>
        </article>
      {/each}
    </div>
  </section>

  <footer>
    <span>pluris.endoftime.works</span>
    <div>
      <a href="https://github.com/EndofTimeWorks/pluris-haven">Source</a>
      <a href="https://github.com/EndofTimeWorks/pluris-haven/issues">Issues</a>
      <a href="/terms">Terms</a>
      <a href="/privacy">Privacy</a>
    </div>
  </footer>
</main>

<style>
  :global(*) {
    box-sizing: border-box;
  }
  :global(body) {
    margin: 0;
    background: #151820;
    color: #f4f0ff;
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
    color: inherit;
  }
  main {
    min-height: 100vh;
  }
  .site-head,
  footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 18px;
    border-bottom: 1px solid #303442;
    padding: 24px clamp(18px, 4vw, 72px) 18px;
  }
  .brand,
  nav,
  .actions,
  footer div {
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .brand {
    font-weight: 800;
    text-decoration: none;
  }
  .mark {
    display: grid;
    width: 34px;
    height: 34px;
    place-items: center;
    border-radius: 9px;
    background: #6750f0;
    font-size: 0.75rem;
  }
  nav {
    flex-wrap: wrap;
    color: #c8c2d4;
    font-size: 0.94rem;
  }
  nav a,
  footer a {
    text-decoration: none;
  }
  nav a:hover,
  nav a:focus-visible,
  footer a:hover,
  footer a:focus-visible {
    text-decoration: underline;
  }
  .intro {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(min(100%, 420px), 1fr));
    gap: clamp(24px, 5vw, 72px);
    align-items: start;
    padding: clamp(34px, 7vw, 90px) clamp(18px, 4vw, 72px) clamp(28px, 5vw, 60px);
  }
  .label {
    margin: 0 0 12px;
    color: #f0ca63;
    font-size: 0.8rem;
    font-weight: 900;
    letter-spacing: 0.12em;
    text-transform: uppercase;
  }
  h1,
  h2,
  h3,
  p {
    margin-top: 0;
  }
  h1 {
    margin-bottom: 14px;
    font-size: clamp(2.7rem, 5vw, 4.8rem);
    line-height: 1;
  }
  h2 {
    margin-bottom: 12px;
    font-size: 1.25rem;
  }
  .lede,
  .notes p,
  li,
  .privacy p {
    color: #c9c4d4;
    line-height: 1.6;
  }
  .lede {
    max-width: 760px;
    margin-bottom: 0;
    font-size: 1.08rem;
  }
  .actions {
    flex-wrap: wrap;
    margin-top: 24px;
  }
  .button {
    display: inline-flex;
    min-height: 46px;
    align-items: center;
    justify-content: center;
    border: 1px solid #464a5c;
    border-radius: 8px;
    padding: 0 15px;
    background: #242832;
    font-weight: 800;
    text-decoration: none;
  }
  .button.primary {
    border-color: #6750f0;
    background: #6750f0;
  }
  .button:hover {
    border-color: #8e7bff;
    background: #2d3240;
  }
  .button.primary:hover {
    background: #7863ff;
  }
  .button span {
    margin-left: 8px;
    color: #ded8ff;
    font-size: 0.82rem;
  }
  .release-note,
  figcaption {
    color: #aaa4b5;
    font-size: 0.9rem;
    line-height: 1.55;
  }
  .release-note {
    max-width: 64ch;
    margin-top: 14px;
  }
  figure {
    max-width: 370px;
    margin: 0;
  }
  figcaption {
    margin-top: 10px;
  }
  .app-preview {
    display: grid;
    gap: 10px;
    border: 1px solid #303442;
    border-radius: 24px;
    padding: 18px 16px 16px;
    background: #1a1e2a;
    font-size: 0.92rem;
  }
  .phone-status {
    display: flex;
    justify-content: space-between;
    padding: 0 4px;
    color: #aaa4b5;
    font-size: 0.78rem;
    font-weight: 700;
  }
  .app-card {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border: 1px solid #34394a;
    border-radius: 12px;
    padding: 12px 14px;
    background: #202430;
  }
  .app-card div {
    display: grid;
    gap: 2px;
  }
  .app-card span {
    color: #c9c4d4;
    font-size: 0.8rem;
  }
  .header-card b {
    border-radius: 5px;
    padding: 2px 8px;
    background: #2e3343;
    color: #f0ca63;
    font-size: 0.68rem;
    letter-spacing: 0.04em;
    text-transform: uppercase;
  }
  .front-card strong {
    font-size: 1.1rem;
  }
  .tile-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
  }
  .tile-grid div {
    border: 1px solid #34394a;
    border-radius: 10px;
    padding: 12px 6px;
    background: #202430;
    color: #c9c4d4;
    font-size: 0.75rem;
    font-weight: 700;
    text-align: center;
  }
  .status-strip {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(min(100%, 200px), 1fr));
    gap: 14px;
    margin: 0;
    border-top: 1px solid #303442;
    padding: 24px clamp(18px, 4vw, 72px);
  }
  .status-strip div,
  .split > div,
  .notes > div {
    border: 1px solid #34394a;
    border-radius: 8px;
    background: #202430;
  }
  .status-strip div {
    padding: 14px 16px;
  }
  .status-strip dt {
    color: #c9c4d4;
    font-size: 0.78rem;
    font-weight: 900;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }
  .status-strip dd {
    margin: 4px 0 0;
    color: #f4f0ff;
    font-size: 1.05rem;
    font-weight: 800;
  }
  .download-callout {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 24px;
    border-top: 1px solid #303442;
    padding: 30px clamp(18px, 4vw, 72px);
    background: #1b1f29;
  }
  .download-callout p:not(.label) {
    max-width: 68ch;
    margin-bottom: 0;
    color: #c9c4d4;
    line-height: 1.6;
  }
  .download-callout .actions {
    flex: 0 0 auto;
    margin-top: 0;
  }
  .split,
  .notes,
  .privacy {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(min(100%, 360px), 1fr));
    gap: 18px;
    border-top: 1px solid #303442;
    padding: 28px clamp(18px, 4vw, 72px);
  }
  .split > div,
  .notes > div {
    padding: 22px;
  }
  ul {
    margin: 0;
    padding-left: 20px;
  }
  li + li {
    margin-top: 7px;
  }
  .notes p {
    margin-bottom: 0;
  }
  .privacy-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(min(100%, 220px), 1fr));
    gap: 14px;
  }
  .privacy article {
    border-left: 3px solid #6750f0;
    padding-left: 16px;
  }
  .privacy h3 {
    margin-bottom: 6px;
    font-size: 1rem;
  }
  .privacy p {
    margin-bottom: 0;
  }
  footer {
    border-top: 1px solid #303442;
    border-bottom: 0;
    padding-bottom: 40px;
    color: #aaa4b5;
    font-size: 0.9rem;
  }
  @media (max-width: 760px) {
    .site-head,
    footer,
    .download-callout {
      align-items: flex-start;
      flex-direction: column;
    }
    .intro {
      padding-top: 34px;
    }
    .download-callout .actions {
      flex: 1;
    }
  }
  @media (max-width: 560px) {
    .button {
      width: 100%;
    }
  }
  @media (forced-colors: active) {
    .mark,
    .button,
    .app-card,
    .tile-grid div,
    .status-strip div {
      border: 1px solid ButtonText;
    }
  }
</style>
