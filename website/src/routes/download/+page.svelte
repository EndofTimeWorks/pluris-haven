<svelte:head>
	<title>Download Pluris Haven</title>
	<meta name="description" content="Download Pluris Haven Android pre-alpha builds." />
</svelte:head>

<main>
	<a class="back" href="/">Back to Pluris Haven</a>
	<section>
		<p class="eyebrow">Android pre-alpha</p>
		<h1>Download</h1>
		<p>
			Android is the only supported client right now. Builds are pre-alpha and may
			need a fresh import after larger data model changes.
		</p>
		<div class="actions">
			<a class="button primary" href="https://github.com/EndofTimeWorks/pluris-haven/releases">
				GitHub Releases
			</a>
			<a class="button" href="https://obtainium.imranr.dev">Obtainium</a>
		</div>
	</section>

	<section>
		<h2>Obtainium setup</h2>
		<ol>
			<li>Add <code>https://github.com/EndofTimeWorks/pluris-haven</code>.</li>
			<li>Enable prereleases.</li>
			<li>Use the APK asset from the latest mobile pre-alpha/dev release.</li>
			<li>If Android says the package differs, uninstall the old package first.</li>
		</ol>
	</section>

	<section>
		<h2>Build locally</h2>
		<pre><code>cd mobile
flutter pub get
flutter build apk --debug</code></pre>
	</section>
</main>

<style>
	@import '../page.css';
</style>
