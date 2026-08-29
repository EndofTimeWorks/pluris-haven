<svelte:head>
  <title>Pluris Haven Privacy</title>
  <meta name="description" content="Privacy and minors safety notes for Pluris Haven." />
</svelte:head>

<main id="main-content" tabindex="-1">
  <a class="back" href="/">Back to Pluris Haven</a>
  <section>
    <p class="eyebrow">Privacy</p>
    <h1>Local by default. Clear before online.</h1>
    <p>
      The app should not need an account for personal local use. Online features should explain what
      data leaves the device before they run.
    </p>
  </section>

  <section>
    <h2>Health-adjacent data</h2>
    <p>
      Plural system tools often hold notes about identity, safety, symptoms, relationships, and
      daily life. Pluris Haven is for personal tracking and journaling. It is not medical care,
      medical advice, crisis support, or a replacement for professional help.
    </p>
  </section>

  <section>
    <h2>What local encryption does and does not hide</h2>
    <p>
      Private text is encrypted with a key held in the device secure store. The current local
      database still needs unencrypted structure to work, including timestamps, row counts,
      relationship links, and status flags. Someone who obtains the raw database could infer
      activity patterns even without reading encrypted names or journal text.
    </p>
    <p>
      Keep device encryption and a screen lock enabled. Android cloud and device-transfer backups
      are disabled for app data, but a full-database encryption design is a separate future project
      rather than a claim this pre-alpha makes today.
    </p>
  </section>

  <section>
    <h2>Minors</h2>
    <p>
      Plural system tools can hold sensitive identity, journal, health-adjacent, and relationship
      data. Cloud accounts for younger users need separate safety and consent rules, not a normal
      signup flow.
    </p>
    <ul>
      <li>No ads or behavioral profiling.</li>
      <li>Private by default.</li>
      <li>Clear deletion and export controls.</li>
      <li>Guardian/consent handling before hosted accounts for younger users.</li>
      <li>Extra care around public profiles, friends, messages, and search.</li>
    </ul>
  </section>

  <section>
    <h2>Optional hosted accounts and backups</h2>
    <p>
      The app works locally without an account. If you choose a hosted account, the server stores
      your email address, display name, account ID, password hash, session and security records, and
      encrypted backup metadata needed to operate that account.
    </p>
    <p>
      Backup contents are encrypted on the device before upload. Pluris Haven stores the encrypted
      chunks but cannot read the system records inside them. The app does not include advertising or
      behavioral profiling.
    </p>
    <p>
      Remote avatar downloads happen only when you import or choose a remote avatar. They contact
      the URL you selected, whose operator has its own privacy practices.
    </p>
  </section>

  <section>
    <h2>Deletion and export</h2>
    <p>
      You can export local data from the app. You can delete individual hosted backups without
      deleting the account, or request account deletion in the app. Account deletion disables the
      account immediately and permanently removes its hosted data after a 30-day recovery period.
    </p>
    <div class="actions">
      <a class="button" href="/terms">Read terms draft</a>
      <a class="button" href="/account-deletion">Delete a hosted account</a>
      <a class="button" href="/support">Report a concern</a>
    </div>
  </section>
</main>

<style>
  @import '../page.css';
</style>
