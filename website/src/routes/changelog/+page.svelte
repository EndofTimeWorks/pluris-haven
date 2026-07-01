<svelte:head>
	<title>Pluris Haven Changelog</title>
	<meta name="description" content="Current Pluris Haven pre-alpha changes and release notes." />
</svelte:head>

<main>
	<a class="back" href="/">Back to Pluris Haven</a>
	<section>
		<p class="eyebrow">Changelog</p>
		<h1>Pre-alpha notes.</h1>
		<p>
			This is the human-readable status page for the current mobile line. GitHub
			releases remain the source for APK files and exact tags.
		</p>
		<div class="actions">
			<a class="button primary" href="https://github.com/EndofTimeWorks/pluris-haven/releases">
				GitHub Releases
			</a>
			<a class="button" href="https://github.com/EndofTimeWorks/pluris-haven/commits/main">
				Commit history
			</a>
		</div>
	</section>

	<section>
		<h2>0.1.0 pre-alpha</h2>
		<ul>
			<li>Local Android app with offline storage.</li>
			<li>Members, archived members, groups, notes, messages, polls, and reminders.</li>
			<li>Custom fronts are stored separately from members.</li>
			<li>Simply Plural and PluralKit import paths are under active testing.</li>
			<li>Dashboard and theme customization are available, but still changing.</li>
		</ul>
	</section>

	<section>
		<h2>Known rough spots</h2>
		<ul>
			<li>Import logs need better row-level detail for failed or skipped data.</li>
			<li>Avatars and very large archives need more device testing.</li>
			<li>Accessibility needs a dedicated TalkBack and keyboard navigation pass.</li>
			<li>Sync, friends, web login, and hosted backup are not ready.</li>
		</ul>
	</section>
</main>

<style>
	@import '../page.css';
</style>
