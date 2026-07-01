<svelte:head>
	<title>Pluris Haven</title>
	<meta
		name="description"
		content="Pluris Haven is a pre-alpha, offline-first app for plural systems."
	/>
</svelte:head>

<script lang="ts">
	const current = [
		['Build', 'Android pre-alpha'],
		['Storage', 'local device database'],
		['Import', 'Simply Plural and PluralKit file work is active'],
		['Sync', 'not on by default; server work comes later']
	];

	const works = [
		'Members, archived members, groups, custom fronts',
		'Front history, current front, status notes',
		'Notes, messages, polls, reminders',
		'Custom fields and imported custom field values',
		'Local import/export and backup restore'
	];

	const rough = [
		'SP-style co-fronting still needs to behave closer to independent front entries',
		'Import details need clearer counts, skips, and per-row errors',
		'Avatars and large archives need more testing',
		'Accessibility needs a full TalkBack/VoiceOver pass'
	];
</script>

<main>
	<header class="site-head">
		<a class="brand" href="/" aria-label="Pluris Haven home">
			<span class="mark" aria-hidden="true">PH</span>
			<span>Pluris Haven</span>
		</a>
		<nav aria-label="Main navigation">
			<a href="/download">Download</a>
			<a href="/docs">Docs</a>
			<a href="/changelog">Changelog</a>
			<a href="/support">Support</a>
			<a href="/privacy">Privacy</a>
			<a href="/app">Web app</a>
		</nav>
	</header>

	<section class="intro">
		<div>
			<p class="label">Pre-alpha</p>
			<h1>Offline-first plural system app.</h1>
			<p class="lede">
				Android first. No account required for local use. Built around importing from
				Simply Plural, keeping data on-device, and adding sync only when it is ready.
			</p>
			<div class="actions">
				<a class="button primary" href="/download">Download Android build</a>
				<a class="button" href="https://github.com/EndofTimeWorks/pluris-haven">GitHub</a>
			</div>
		</div>

		<aside class="status-panel" aria-label="Current project status">
			<h2>Current state</h2>
			<dl>
				{#each current as [term, detail]}
					<div>
						<dt>{term}</dt>
						<dd>{detail}</dd>
					</div>
				{/each}
			</dl>
		</aside>
	</section>

	<section class="split">
		<div>
			<h2>Works now</h2>
			<ul>
				{#each works as item}
					<li>{item}</li>
				{/each}
			</ul>
		</div>
		<div>
			<h2>Still rough</h2>
			<ul>
				{#each rough as item}
					<li>{item}</li>
				{/each}
			</ul>
		</div>
	</section>

	<section class="notes">
		<div>
			<h2>Why it exists</h2>
			<p>
				Pluris Haven is meant to be a practical replacement path for people who need
				their data available without depending on someone else’s hosted app.
			</p>
		</div>
		<div>
			<h2>What the site is for</h2>
			<p>
				This site hosts downloads, basic docs, privacy notes, and eventually the web UI.
				The web UI will live at <a href="/app">/app</a> once the shared data model is
				stable enough.
			</p>
		</div>
	</section>

	<footer>
		<span>pluris.endoftime.works</span>
		<div>
			<a href="https://github.com/EndofTimeWorks/pluris-haven/releases">Releases</a>
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
			ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
			sans-serif;
	}

	:global(a) {
		color: inherit;
	}

	main {
		width: 100%;
		min-height: 100vh;
		padding: 0;
	}

	.site-head {
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
		text-decoration: none;
		font-weight: 800;
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
	footer a:hover,
	.notes a:hover {
		text-decoration: underline;
	}

	.intro {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(min(100%, 420px), 1fr));
		gap: clamp(24px, 5vw, 72px);
		align-items: start;
		padding: clamp(34px, 7vw, 90px) clamp(18px, 4vw, 72px)
			clamp(28px, 5vw, 60px);
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
	p {
		margin-top: 0;
	}

	h1 {
		margin-bottom: 14px;
		font-size: clamp(2.7rem, 5vw, 4.8rem);
		line-height: 1;
		letter-spacing: 0;
	}

	h2 {
		margin-bottom: 12px;
		font-size: 1.15rem;
	}

	.lede,
	.notes p,
	li,
	dd {
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
		min-height: 43px;
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

	.status-panel,
	.split > div,
	.notes > div {
		border: 1px solid #34394a;
		border-radius: 8px;
		background: #202430;
	}

	.status-panel {
		padding: 22px;
	}

	dl {
		display: grid;
		gap: 12px;
		margin: 0;
	}

	dl div {
		border-top: 1px solid #34394a;
		padding-top: 12px;
	}

	dt {
		margin-bottom: 3px;
		color: #f4f0ff;
		font-weight: 800;
	}

	dd {
		margin: 0;
	}

	.split,
	.notes {
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

	.notes a {
		color: #d7cdfd;
		font-weight: 700;
	}

	footer {
		display: flex;
		justify-content: space-between;
		gap: 18px;
		border-top: 1px solid #303442;
		padding: 22px clamp(18px, 4vw, 72px) 40px;
		color: #aaa4b5;
		font-size: 0.9rem;
	}

	@media (max-width: 760px) {
		.site-head,
		footer {
			align-items: flex-start;
			flex-direction: column;
		}

		.intro {
			padding-top: 34px;
		}
	}
</style>
