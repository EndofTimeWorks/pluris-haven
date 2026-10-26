<svelte:head>
  <title>Pluris Haven Privacy</title>
  <meta name="description" content="Privacy and minors safety notes for Pluris Haven." />
</svelte:head>

<main id="main-content" tabindex="-1">
  <a class="back" href="/">Back to Pluris Haven</a>
  <section>
    <p class="eyebrow">Privacy</p>
    <h1>Privacy</h1>
    <p>
      Pluris Haven is operated by EndofTimeWorks LLC, doing business as EndofTimeWorks. The app does
      not need an account for personal local use. There is no public Pluris Haven server or hosted
      account service in this pre-alpha. Online features should explain what data leaves the device
      before they run.
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
    <h2>Online services</h2>
    <p>
      Hosted accounts, online backups, and device sync are not currently offered. Local encrypted
      archives can be exported and restored without an account. The app does not include advertising
      or behavioural profiling.
    </p>
    <p>
      Remote avatar downloads happen only when you import or choose a remote avatar. They contact
      the URL you selected, whose operator has its own privacy practices.
    </p>
  </section>

  <section>
    <h2>Deletion and export</h2>
    <p>
      You can export local data from the app. Local data and copies you have exported remain under
      your control. There is no public hosted account to delete in this pre-alpha.
    </p>
    <div class="actions">
      <a class="button" href="/terms">Read terms draft</a>
      <a class="button" href="/account-deletion">Account deletion status</a>
      <a class="button" href="/support">Report a concern</a>
    </div>
  </section>
</main>

<style>
  @import '../page.css';
</style>
