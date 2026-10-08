<script lang="ts">
  import { mobileRelease } from '#lib/release.js';
</script>

<svelte:head>
  <title>Pluris Haven Changelog</title>
  <meta name="description" content="Current Pluris Haven pre-alpha changes and release notes." />
</svelte:head>

<main id="main-content" tabindex="-1">
  <a class="back" href="/">Back to Pluris Haven</a>
  <section>
    <p class="eyebrow">Changelog</p>
    <h1>Pre-alpha notes.</h1>
    <p>
      This is the human-readable status page for the current mobile line. GitHub releases remain the
      source for APK files and exact tags.
    </p>
    <div class="actions">
      <a class="button primary" href={mobileRelease.releaseUrl}> Current release </a>
      <a class="button" href="https://github.com/EndofTimeWorks/pluris-haven/commits/main">
        Commit history
      </a>
    </div>
  </section>

  <section>
    <h2>0.3.0-pre-alpha.5</h2>
    <p>Release candidate notes for build <code>0.3.0-pre-alpha.5+3005</code>.</p>
    <ul>
      <li>
        Startup, encrypted storage, migrations, imports, and destructive record lifecycles have
        stronger failure handling and recovery safeguards.
      </li>
      <li>
        PluralPort Draft v0.1 portable file import and export cover the fields currently defined by
        the Draft. Underspecified records stay in a Pluris Haven extension with a compatibility
        warning; this is not complete format coverage or live sync.
      </li>
      <li>
        Imports preserve more unsupported data and original source provenance instead of silently
        presenting a lossy conversion as complete.
      </li>
      <li>
        Pluris Haven has new app icons and expanded colour, typography, spacing, and navigation
        controls.
      </li>
      <li>
        Friends remains hidden while incomplete, and Sync settings now state that general device
        sync is unavailable.
      </li>
      <li>
        The first encrypted native <code>.pluris</code> archive-frame primitive is in place, but a complete
        backup and restore workflow is not yet available.
      </li>
      <li>
        Dependencies and build tools are updated, and the release pipeline now prevents Dependabot
        branches from publishing debug releases.
      </li>
      <li>
        Repository-owned product links now use <code>plurishaven.app</code>, alongside assorted
        stability, accessibility, migration, and product-truth fixes.
      </li>
    </ul>
  </section>

  <section>
    <h2>Published download</h2>
    <ul>
      <li>Current published website download: <code>{mobileRelease.version}</code>.</li>
      <li>
        Local Android app with encrypted storage, encrypted backup snapshots, and a restore
        rehearsal before archive imports.
      </li>
      <li>
        Members, archived members, groups, tags, custom fields, notes, journals, messages, polls,
        reminders, and front history.
      </li>
      <li>Custom fronts are stored separately from members and do not import as alters.</li>
      <li>
        Simply Plural, PluralKit, Tupperbox, and PluralSpace import paths are covered for testing;
        the Prism encrypted path remains planned.
      </li>
      <li>
        Avatar ZIPs are supported for Simply Plural imports; remote avatar links are localized only
        after public-address and redirect safety checks.
      </li>
      <li>
        Dashboard, accessibility, language, and theme customization are available, with named avatar
        semantics and persisted high-contrast/reduced-motion settings.
      </li>
      <li>
        Versioned releases include an unsigned iOS IPA for AltStore, SideStore, or Sideloadly to
        re-sign.
      </li>
      <li>
        Android screenshots and screen recordings of the app show a black rectangle instead of
        member, front, or journal content.
      </li>
      <li>
        An optional app lock can require the device's own screen lock before the app opens, and
        re-locks whenever it is backgrounded.
      </li>
      <li>
        Copying the local archive JSON marks it sensitive on Android 13+, so the system clipboard
        preview does not show the plaintext content.
      </li>
      <li>Avatar photos are excluded from iOS backups, matching Android's existing behavior.</li>
    </ul>
  </section>

  <section>
    <h2>Known rough spots</h2>
    <ul>
      <li>Imports are best-effort and need more large-system device testing.</li>
      <li>
        Avatar downloads depend on the source service staying reachable unless an avatar ZIP is
        attached; malformed or oversized archives are rejected.
      </li>
      <li>
        Accessibility has toggles and labels, but still needs a full TalkBack, VoiceOver, keyboard,
        and low-mobility pass.
      </li>
      <li>
        Public server launch, bidirectional sync, signed iOS distribution, and store distribution
        are not ready.
      </li>
    </ul>
  </section>
</main>

<style>
  @import '../page.css';
</style>
