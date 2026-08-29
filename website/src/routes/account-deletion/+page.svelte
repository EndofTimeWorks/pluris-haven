<svelte:head>
  <title>Delete a Pluris Haven account</title>
  <meta
    name="description"
    content="How to delete a Pluris Haven hosted account and what happens to its data."
  />
</svelte:head>

<main id="main-content" tabindex="-1">
  <a class="back" href="/">Back to Pluris Haven</a>
  <section>
    <p class="eyebrow">Account deletion</p>
    <h1>Delete a Pluris Haven hosted account</h1>
    <p>
      This page applies to accounts operated by Pluris Haven. For a community or self-hosted server,
      contact that server’s operator instead.
    </p>
  </section>

  <section>
    <h2>Request deletion in the app</h2>
    <ol>
      <li>Open the Account section and connect to the server that holds the account.</li>
      <li>Sign in, then choose <strong>Delete server account</strong>.</li>
      <li>Enter the current password and confirm.</li>
    </ol>
    <p>
      If you cannot sign in, use the password-reset option for that server first. The app’s local
      records stay on the device; deleting a hosted account does not erase them.
    </p>
  </section>

  <section>
    <h2>What deletion removes</h2>
    <p>
      The request immediately disables the account and revokes its sessions. After a 30-day recovery
      period, Pluris Haven deletes the hosted account’s email address, display name, password hash,
      sessions, friend and block relationships, encrypted backup metadata, and encrypted backup
      chunks. Security audit entries are retained only after their account link is removed.
    </p>
    <p>
      During the 30-day period, resetting the password and signing in restores the account. After
      the purge, the account and its hosted backups cannot be recovered.
    </p>
  </section>

  <section>
    <h2>Delete a backup without deleting the account</h2>
    <p>
      Open the connected server account in the app and use the delete button beside an encrypted
      backup. That removes the selected hosted backup while leaving the account active.
    </p>
  </section>

  <section>
    <h2>Need help?</h2>
    <p>
      If the in-app route is unavailable, <a href="/support">contact Pluris Haven support</a> with the
      server address and the account email address. Do not include your password or backup files.
    </p>
  </section>
</main>

<style>
  @import '../page.css';
</style>
