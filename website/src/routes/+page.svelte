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
		['Import', 'Simply Plural, PluralKit, Tupperbox, PluralSpace, Prism'],
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

	const previewTiles = ['Members', 'Front history', 'Custom fronts', 'Groups', 'Notes', 'Import / export'];
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
		<div class="intro-copy">
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

		<aside class="app-preview" aria-label="Preview of the Pluris Haven mobile dashboard">
			<div class="phone-status" aria-hidden="true">
				<span>8:32</span>
				<span>87%</span>
			</div>
			<div class="app-card header-card">
				<div>
					<strong>Pluris Haven</strong>
					<span>saved on device</span>
				</div>
				<b>pre-alpha</b>
			</div>
			<div class="app-card front-card">
				<span>Currently fronting</span>
				<strong>None</strong>
			</div>
			<div class="tile-grid">
				{#each previewTiles as tile}
					<div>{tile}</div>
				{/each}
			</div>
		</aside>
	</section>

	<section class="status-strip" aria-label="Current project status">
		{#each current as [term, detail]}
			<div>
				<span>{term}</span>
				<strong>{detail}</strong>
			</div>
		{/each}
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
	li {
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

	.split > div,
	.notes > div {
		border: 1px solid #34394a;
		border-radius: 8px;
		background: #202430;
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

	.app-preview {
		display: grid;
		gap: 10px;
		border: 1px solid #303442;
		border-radius: 24px;
		max-width: 370px;
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
		font-weight: 900;
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
		border-top: 1px solid #303442;
		padding: 24px clamp(18px, 4vw, 72px);
	}

	.status-strip div {
		border: 1px solid #34394a;
		border-radius: 8px;
		padding: 14px 16px;
		background: #202430;
	}

	.status-strip span {
		display: block;
		color: #c9c4d4;
		font-size: 0.78rem;
		font-weight: 900;
		letter-spacing: 0.08em;
		text-transform: uppercase;
	}

	.status-strip strong {
		margin-top: 4px;
		font-size: 1.05rem;
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
