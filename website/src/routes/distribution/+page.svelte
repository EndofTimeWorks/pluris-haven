<script lang="ts">
  import { mobileRelease } from '$lib/release';
  import { obtainiumRedirectUrl, repositoryUrl } from '$lib/obtainium-config';
</script>

<svelte:head>
  <title>Pluris Haven Distribution</title>
  <meta name="description" content="Install channels and update notes for Pluris Haven." />
</svelte:head>

<main id="main-content" tabindex="-1">
  <a class="back" href="/">Back to Pluris Haven</a>
  <section>
    <p class="eyebrow">Distribution</p>
    <h1>GitHub first. Store later.</h1>
    <p>
      Pre-alpha builds ship through GitHub Releases so testing is not tied to a store account. Local
      use should stay available even if a hosted service or app store is not ready somewhere.
    </p>
  </section>

  <section>
    <h2>Android</h2>
    <ul>
      <li>Package id: <code>works.endoftime.plurishaven</code></li>
      <li>Canonical APK: <code>pluris-haven-&lt;version&gt;.apk</code></li>
      <li>Debug tags: <code>debug-v*</code></li>
      <li>Versioned tags: <code>mobile-v&lt;version&gt;</code></li>
      <li>Current release: <code>{mobileRelease.version}</code></li>
    </ul>
    <div class="actions">
      <a class="button primary" href={mobileRelease.universalApk.url}> Download signed APK </a>
      <a class="button" href={mobileRelease.releaseUrl}>Release files</a>
      <a class="button" href={obtainiumRedirectUrl}>Get it on Obtainium</a>
    </div>
  </section>

  <section>
    <h2>Obtainium</h2>
    <ol>
      <li>Use <strong>Get it on Obtainium</strong> to open the checked GitHub Releases source.</li>
      <li>Confirm the canonical Play-signed APK filter.</li>
      <li>Future versioned pre-alpha releases are tracked by Android version code.</li>
    </ol>
    <p>
      If Android says the downloaded package does not match the installed app, the old install is
      from an earlier experimental package id. Uninstall it once, then install the current build.
    </p>
    <p>
      Build codes must stay above <code>2000</code>. Android will reject a lower code even when the
      visible SemVer string looks newer.
    </p>
    <p>Manual fallback: add <code>{repositoryUrl}</code> as a GitHub source in Obtainium.</p>
  </section>

  <section>
    <h2>iOS</h2>
    <p>
      Versioned releases include an <a href={mobileRelease.unsignedIpaUrl}>unsigned IPA</a> for
      bundle id
      <code>works.endoftime.plurishaven</code>. AltStore, SideStore, or Sideloadly must re-sign it
      before installation. Signed IPA and TestFlight builds still need Apple credentials and
      physical-device validation.
    </p>
    <p>
      When it is ready, SideStore/AltStore should be available before relying on App Store
      distribution.
    </p>
  </section>
</main>

<style>
  @import '../page.css';
</style>
