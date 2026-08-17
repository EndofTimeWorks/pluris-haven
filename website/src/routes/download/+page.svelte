<script lang="ts">
  import { mobileRelease } from '$lib/release';
</script>

<svelte:head>
  <title>Download Pluris Haven</title>
  <meta
    name="description"
    content="Download, install, and verify the Pluris Haven Android pre-alpha."
  />
</svelte:head>

<main id="main-content" tabindex="-1">
  <a class="back" href="/">Back to Pluris Haven</a>
  <section>
    <p class="eyebrow">Android pre-alpha</p>
    <h1>Install the Android build.</h1>
    <p>
      This is a signed release build for Android 7 and newer. It is pre-alpha: keep an encrypted
      export of data you care about, and expect some import or data-model changes before stable.
    </p>
    <ul class="data-list">
      <li><span>Current version</span><strong>{mobileRelease.version}</strong></li>
      <li><span>Package id</span><strong>works.endoftime.plurishaven</strong></li>
      <li><span>Published</span><strong>{mobileRelease.published}</strong></li>
      <li><span>Minimum Android version</span><strong>Android 7 (API 24)</strong></li>
    </ul>
    <div class="actions">
      <a class="button primary" href={mobileRelease.universalApk.url}>
        Download universal APK ({mobileRelease.universalApk.size})
      </a>
      <a class="button" href={mobileRelease.arm64Apk.url}>
        Smaller 64-bit APK ({mobileRelease.arm64Apk.size})
      </a>
    </div>
    <p class="muted">
      Choose universal if you are unsure. Most current phones can use the smaller 64-bit build.
    </p>
  </section>

  <section>
    <h2>Install it</h2>
    <ol>
      <li>Download the universal APK above.</li>
      <li>Open the downloaded file.</li>
      <li>Allow installs from your browser or file manager when Android asks.</li>
      <li>Install Pluris Haven, then turn that permission back off if you prefer.</li>
      <li>
        If Android says the package differs, check that the installed app uses
        <code>works.endoftime.plurishaven</code>. Older experimental builds used a different id and
        need to be uninstalled first.
      </li>
    </ol>
  </section>

  <section>
    <h2>Verify the file</h2>
    <p>
      GitHub publishes a checksum list and build record beside every versioned release. On Linux or
      macOS, compare the downloaded universal APK with the expected SHA-256 value:
    </p>
    <pre><code>sha256sum {mobileRelease.universalApk.name}</code></pre>
    <p class="hash"><strong>Expected:</strong> <code>{mobileRelease.universalApk.sha256}</code></p>
    <div class="actions">
      <a class="button" href={mobileRelease.checksumsUrl}>All SHA-256 checksums</a>
      <a class="button" href={mobileRelease.buildMetadataUrl}>Build metadata</a>
      <a class="button" href={mobileRelease.releaseUrl}>Release notes</a>
    </div>
  </section>

  <section>
    <h2>Automatic updates with Obtainium</h2>
    <ol>
      <li>Install Obtainium from its official source.</li>
      <li>Add <code>https://github.com/EndofTimeWorks/pluris-haven</code>.</li>
      <li>Enable prereleases.</li>
      <li>Filter APK assets to the universal APK, ending in <code>-universal.apk</code>.</li>
    </ol>
    <p>
      Obtainium is a separate project. Review what it will install before enabling automatic
      updates.
    </p>
    <div class="actions">
      <a class="button" href="https://obtainium.imranr.dev">Obtainium website</a>
    </div>
  </section>

  <section>
    <h2>iPhone and iPad</h2>
    <p>
      The release also includes an <a href={mobileRelease.unsignedIpaUrl}>unsigned iOS IPA</a>. It
      will not install by itself. AltStore, SideStore, or Sideloadly must sign it with your Apple
      account first, and iOS may require it to be signed again every seven days with a free account.
      This path still needs broader physical-device testing.
    </p>
  </section>

  <section>
    <h2>Not medical care</h2>
    <p>
      Pluris Haven is a personal tracking and journaling tool. It is not medical advice, crisis
      support, or a replacement for professional help.
    </p>
  </section>
</main>

<style>
  @import '../page.css';
  .hash {
    overflow-wrap: anywhere;
  }
</style>
