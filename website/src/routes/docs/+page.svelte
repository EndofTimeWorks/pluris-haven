<svelte:head>
	<title>Pluris Haven Docs</title>
	<meta name="description" content="Basic docs for Pluris Haven setup, imports, and hosting." />
</svelte:head>

<main>
	<a class="back" href="/">Back to Pluris Haven</a>
	<section>
		<p class="eyebrow">Docs</p>
		<h1>Use it locally first.</h1>
		<p>
			Pluris Haven is being built around local data. Import your archive, check the
			import log, then export a backup before testing anything risky.
		</p>
	</section>

	<section>
		<h2>Import order</h2>
		<ol>
			<li>Export JSON from the source app.</li>
			<li>Import the JSON in Pluris Haven.</li>
			<li>Open the import job details and check skipped or failed rows.</li>
			<li>Confirm members, groups, custom fronts, front history, and avatars.</li>
			<li>Export a Pluris Haven backup.</li>
		</ol>
	</section>

	<section>
		<h2>Self-hosted site deploy</h2>
		<p>
			The public site is static. On a pull-only host, pull the repo, build, and serve
			<code>website/build</code> with nginx, Caddy, or any static file server.
		</p>
		<pre><code>cd /srv/pluris-haven
git pull --ff-only
cd website
pnpm install --frozen-lockfile
pnpm build</code></pre>
	</section>
</main>

<style>
	@import '../page.css';
</style>
