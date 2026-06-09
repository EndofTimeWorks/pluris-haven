<script lang="ts">
	const localItems = [
		'fronts',
		'logs',
		'journal',
		'chat',
		'polls',
		'folders',
		'archive',
		'terms',
		'import',
		'export'
	];

	const onlineItems = ['friends', 'sync', 'PluralKit', 'chat bridges', 'hosted backup'];
</script>

<svelte:head>
	<title>Pluris Haven</title>
	<meta name="description" content="Project status for Pluris Haven." />
</svelte:head>

<main>
	<header>
		<h1>Pluris Haven</h1>
		<p>Offline-first app for plural systems. Android first. Web later.</p>
	</header>

	<section>
		<h2>Local app</h2>
		<p>No account required. No network required for normal use.</p>
		<div class="grid">
			{#each localItems as item}
				<span>{item}</span>
			{/each}
		</div>
	</section>

	<section>
		<h2>Online options</h2>
		<p>Off by default. Each connection needs a data notice before setup.</p>
		<ul>
			{#each onlineItems as item}
				<li>{item}</li>
			{/each}
		</ul>
	</section>

	<section>
		<h2>Current build</h2>
		<ul>
			<li>Android: <code>android</code></li>
			<li>Website: <code>website</code></li>
			<li>iOS: planned</li>
		</ul>
	</section>
</main>

<style>
	:global(body) {
		margin: 0;
		background: #f8fafc;
		color: #111827;
		font-family:
			Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
	}

	main {
		max-width: 920px;
		margin: 0 auto;
		padding: 32px 16px 56px;
	}

	header,
	section {
		border-bottom: 1px solid #dbe3ee;
		padding: 22px 0;
	}

	h1,
	h2,
	p {
		margin-top: 0;
	}

	h1 {
		margin-bottom: 8px;
		font-size: 2rem;
		letter-spacing: 0;
	}

	h2 {
		margin-bottom: 8px;
		font-size: 1.1rem;
		letter-spacing: 0;
	}

	p,
	li,
	span {
		color: #374151;
		line-height: 1.5;
	}

	.grid {
		display: flex;
		flex-wrap: wrap;
		gap: 8px;
		margin-top: 14px;
	}

	span {
		border: 1px solid #cbd5e1;
		border-radius: 6px;
		background: #ffffff;
		padding: 6px 9px;
	}

	ul {
		margin: 12px 0 0;
		padding-left: 20px;
	}

	code {
		border-radius: 4px;
		background: #e5e7eb;
		padding: 2px 5px;
	}
</style>
