<svelte:head>
	<title>Pluris Haven</title>
	<meta
		name="description"
		content="Offline-first app for plural systems. Import from Simply Plural, keep data local, and sync only when you choose."
	/>
</svelte:head>

<script lang="ts">
	const workingNow = [
		'Android pre-alpha builds',
		'Local members, groups, custom fronts, notes, polls, reminders, and front history',
		'Simply Plural and PluralKit file import work in progress',
		'Local backup and restore',
		'Custom colors and dashboard settings'
	];

	const roadmap = [
		['Now', 'Fix import edge cases, SP-style fronting, avatars, and editing flows.'],
		['Alpha', 'Finish accessibility pass, stronger import logs, and stable local backups.'],
		['Beta', 'Web UI, optional sync, friends/trust rules, and push notifications.'],
		['Later', 'iOS, watch apps, public API, and self-host server tooling.']
	];
</script>

<main>
	<nav class="topbar" aria-label="Main navigation">
		<a class="brand" href="/">
			<span class="mark" aria-hidden="true">PH</span>
			<span>Pluris Haven</span>
		</a>
		<div class="navlinks">
			<a href="/download">Download</a>
			<a href="/docs">Docs</a>
			<a href="/privacy">Privacy</a>
			<a href="/app">Web app</a>
		</div>
	</nav>

	<section class="hero">
		<div class="hero-copy">
			<p class="eyebrow">Pre-alpha / offline first</p>
			<h1>A local-first home for plural system tools.</h1>
			<p class="lede">
				Track members, fronts, notes, groups, and imports without needing an account.
				Sync and sharing will stay optional.
			</p>
			<div class="actions">
				<a class="button primary" href="/download">Get Android build</a>
				<a class="button" href="https://github.com/EndofTimeWorks/pluris-haven">Source</a>
			</div>
		</div>

		<div class="phone-preview" aria-label="App preview">
			<div class="phone-bar">
				<span></span>
				<span></span>
				<span></span>
			</div>
			<div class="screen-title">
				<div>
					<strong>Pluris Haven</strong>
					<small>saved on device</small>
				</div>
				<span class="status">pre-alpha</span>
			</div>
			<div class="front-card">
				<span class="accent"></span>
				<div>
					<small>Currently fronting</small>
					<strong>None</strong>
				</div>
			</div>
			<div class="grid">
				<span>Members</span>
				<span>Front history</span>
				<span>Groups</span>
				<span>Notes</span>
				<span>Import / export</span>
				<span>Sync</span>
			</div>
		</div>
	</section>

	<section class="band">
		<div>
			<p class="eyebrow">Current build</p>
			<h2>Useful, but not finished.</h2>
		</div>
		<ul class="check-list">
			{#each workingNow as item}
				<li>{item}</li>
			{/each}
		</ul>
	</section>

	<section class="columns">
		<article>
			<h2>Import first</h2>
			<p>
				The goal is simple: bring Simply Plural data over cleanly, keep avatar files
				local, preserve front history, and make bad imports explain themselves.
			</p>
		</article>
		<article>
			<h2>Private by default</h2>
			<p>
				No account is needed for local use. Online features should explain what leaves
				the device before they connect.
			</p>
		</article>
		<article>
			<h2>Web UI later</h2>
			<p>
				The site is built in SvelteKit so it can grow into a web app without throwing
				away the public site.
			</p>
		</article>
	</section>

	<section class="roadmap">
		<div class="section-head">
			<p class="eyebrow">Roadmap</p>
			<h2>What happens next</h2>
		</div>
		<div class="timeline">
			{#each roadmap as [label, text]}
				<div class="step">
					<strong>{label}</strong>
					<p>{text}</p>
				</div>
			{/each}
		</div>
	</section>

	<footer>
		<span>pluris.endoftime.works</span>
		<div>
			<a href="/privacy">Privacy</a>
			<a href="/docs">Docs</a>
			<a href="https://github.com/EndofTimeWorks/pluris-haven/issues">Issues</a>
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
			Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
			sans-serif;
	}

	:global(a) {
		color: inherit;
		text-decoration: none;
	}

	main {
		min-height: 100vh;
		background:
			linear-gradient(180deg, rgba(39, 42, 55, 0.96), #151820 34rem),
			#151820;
	}

	.topbar,
	.hero,
	.band,
	.columns,
	.roadmap,
	footer {
		width: min(1120px, calc(100% - 32px));
		margin: 0 auto;
	}

	.topbar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 20px;
		padding: 22px 0;
	}

	.brand,
	.navlinks {
		display: flex;
		align-items: center;
		gap: 12px;
	}

	.brand {
		font-weight: 800;
	}

	.mark {
		display: grid;
		width: 36px;
		height: 36px;
		place-items: center;
		border-radius: 11px;
		background: #6750f0;
		font-size: 0.78rem;
	}

	.navlinks {
		color: #d6d0e4;
		font-size: 0.92rem;
	}

	.navlinks a {
		padding: 8px 10px;
		border-radius: 9px;
	}

	.navlinks a:hover,
	.navlinks a:focus-visible {
		background: #303442;
	}

	.hero {
		display: grid;
		grid-template-columns: minmax(0, 1.05fr) minmax(300px, 0.75fr);
		align-items: center;
		gap: 54px;
		padding: 76px 0 84px;
	}

	.eyebrow {
		margin: 0 0 10px;
		color: #f0ca63;
		font-size: 0.78rem;
		font-weight: 900;
		letter-spacing: 0.14em;
		text-transform: uppercase;
	}

	h1,
	h2,
	p {
		margin-top: 0;
	}

	h1 {
		max-width: 760px;
		margin-bottom: 18px;
		font-size: clamp(2.7rem, 8vw, 5.9rem);
		line-height: 0.95;
		letter-spacing: 0;
	}

	h2 {
		margin-bottom: 12px;
		font-size: clamp(1.45rem, 3vw, 2.4rem);
		line-height: 1.05;
	}

	.lede,
	article p,
	.step p {
		color: #c9c4d4;
		line-height: 1.65;
	}

	.lede {
		max-width: 620px;
		font-size: 1.08rem;
	}

	.actions {
		display: flex;
		flex-wrap: wrap;
		gap: 12px;
		margin-top: 28px;
	}

	.button {
		display: inline-flex;
		min-height: 46px;
		align-items: center;
		justify-content: center;
		border: 1px solid #464a5c;
		border-radius: 10px;
		padding: 0 18px;
		background: #242832;
		color: #f4f0ff;
		font-weight: 800;
	}

	.button.primary {
		border-color: #6750f0;
		background: #6750f0;
	}

	.phone-preview {
		position: relative;
		border: 1px solid #44485a;
		border-radius: 34px;
		padding: 18px;
		background: #1e222d;
		box-shadow: 0 34px 80px rgba(0, 0, 0, 0.34);
	}

	.phone-bar {
		display: flex;
		justify-content: space-between;
		padding: 4px 6px 18px;
		color: #cbc5d5;
	}

	.phone-bar span {
		width: 42px;
		height: 6px;
		border-radius: 99px;
		background: #3a3f50;
	}

	.screen-title,
	.front-card {
		border: 1px solid #3b4052;
		border-radius: 18px;
		background: #272b38;
	}

	.screen-title {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 18px;
		padding: 18px;
	}

	small {
		display: block;
		color: #b8b1c3;
	}

	.status {
		border-radius: 999px;
		padding: 6px 9px;
		background: #3b3020;
		color: #f0ca63;
		font-size: 0.78rem;
		font-weight: 900;
	}

	.front-card {
		display: flex;
		gap: 14px;
		margin-top: 12px;
		padding: 18px;
	}

	.accent {
		width: 5px;
		border-radius: 99px;
		background: #8068ff;
	}

	.front-card strong {
		display: block;
		margin-top: 4px;
		font-size: 1.65rem;
	}

	.grid {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: 10px;
		margin-top: 12px;
	}

	.grid span {
		display: grid;
		min-height: 74px;
		place-items: center;
		border-radius: 16px;
		background: #2b3040;
		color: #e8e2f0;
		font-weight: 800;
		text-align: center;
	}

	.band,
	.columns,
	.roadmap {
		padding: 54px 0;
		border-top: 1px solid #303442;
	}

	.band {
		display: grid;
		grid-template-columns: minmax(0, 0.7fr) minmax(0, 1fr);
		gap: 40px;
	}

	.check-list {
		display: grid;
		gap: 12px;
		margin: 0;
		padding: 0;
		list-style: none;
	}

	.check-list li {
		border: 1px solid #3a3f50;
		border-radius: 12px;
		padding: 13px 15px;
		background: #222631;
		color: #e5dfef;
	}

	.columns {
		display: grid;
		grid-template-columns: repeat(3, minmax(0, 1fr));
		gap: 16px;
	}

	article {
		border: 1px solid #3a3f50;
		border-radius: 18px;
		padding: 22px;
		background: #222631;
	}

	article h2 {
		font-size: 1.2rem;
	}

	article p,
	.step p {
		margin-bottom: 0;
	}

	.section-head {
		margin-bottom: 22px;
	}

	.timeline {
		display: grid;
		gap: 12px;
	}

	.step {
		display: grid;
		grid-template-columns: 92px minmax(0, 1fr);
		gap: 18px;
		border-left: 4px solid #6750f0;
		padding: 16px 18px;
		background: #222631;
	}

	.step strong {
		color: #f0ca63;
	}

	footer {
		display: flex;
		justify-content: space-between;
		gap: 20px;
		padding: 34px 0 46px;
		color: #9e97aa;
	}

	footer div {
		display: flex;
		gap: 16px;
	}

	@media (max-width: 780px) {
		.topbar {
			align-items: flex-start;
			flex-direction: column;
		}

		.navlinks {
			flex-wrap: wrap;
		}

		.hero,
		.band,
		.columns {
			grid-template-columns: 1fr;
		}

		.hero {
			padding-top: 38px;
		}

		.phone-preview {
			border-radius: 24px;
		}

		footer {
			flex-direction: column;
		}
	}
</style>
