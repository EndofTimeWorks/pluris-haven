<svelte:head>
  <title>Pluris Haven Distribution</title>
  <meta name="description" content="Install channels and update notes for Pluris Haven." />
</svelte:head>

<main>
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
      <li>Dev APK asset: <code>pluris-haven-dev.apk</code></li>
      <li>Dev tags: <code>mobile-v0.2.0-pre-alpha.N.dev.N+BUILD</code></li>
      <li>Versioned tags: <code>mobile-v0.2.0-pre-alpha.N+BUILD</code></li>
      <li>Current release: <code>0.2.0-pre-alpha.2+2008</code></li>
    </ul>
    <div class="actions">
      <a class="button primary" href="https://github.com/EndofTimeWorks/pluris-haven/releases">
        GitHub Releases
      </a>
      <a class="button" href="https://obtainium.imranr.dev">Obtainium</a>
    </div>
  </section>

  <section>
    <h2>Obtainium</h2>
    <ol>
      <li>Add <code>https://github.com/EndofTimeWorks/pluris-haven</code>.</li>
      <li>Enable prereleases for dev builds.</li>
      <li>Use the APK asset named <code>pluris-haven-dev.apk</code>.</li>
      <li>Sort releases by date.</li>
    </ol>
    <p>
      If Android says the downloaded package does not match the installed app, the old install is
      from an earlier experimental package id. Uninstall it once, then install the current build.
    </p>
    <p>
      Build codes must stay above <code>2000</code>. Android will reject a lower code even when the
      visible SemVer string looks newer.
    </p>
  </section>

  <section>
    <h2>iOS</h2>
    <p>
      Versioned releases include an unsigned IPA for bundle id
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
