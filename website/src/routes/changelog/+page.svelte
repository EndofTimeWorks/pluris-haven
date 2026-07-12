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
		<h2>0.2.0 pre-alpha</h2>
		<ul>
			<li>Current dev line: <code>0.2.0-pre-alpha.1.dev.6+2004</code>.</li>
			<li>Local Android app with offline storage and a restore rehearsal before archive imports.</li>
			<li>Members, archived members, groups, tags, custom fields, notes, journals, messages, polls, reminders, and front history.</li>
			<li>Custom fronts are stored separately from members and do not import as alters.</li>
			<li>Simply Plural, PluralKit, Tupperbox, and PluralSpace import paths are available for testing.</li>
			<li>Avatar ZIPs are supported for Simply Plural imports; remote avatar links may be localized during import.</li>
			<li>Dashboard, accessibility, language, and theme customization are available, but still changing.</li>
		</ul>
	</section>

	<section>
		<h2>Known rough spots</h2>
		<ul>
			<li>Imports are best-effort and need more large-system device testing.</li>
			<li>Avatar downloads depend on the source service staying reachable unless an avatar ZIP is attached.</li>
			<li>Accessibility has toggles and labels, but still needs a full TalkBack, VoiceOver, keyboard, and low-mobility pass.</li>
			<li>Sync, friends, web login, hosted backup, iOS, and store distribution are not ready.</li>
		</ul>
	</section>
</main>

<style>
	@import '../page.css';
</style>
