<svelte:head>
	<title>Pluris Haven Privacy</title>
	<meta name="description" content="Privacy and minors safety notes for Pluris Haven." />
</svelte:head>

<main>
	<a class="back" href="/">Back to Pluris Haven</a>
	<section>
		<p class="eyebrow">Privacy</p>
		<h1>Local by default. Clear before online.</h1>
		<p>
			The app should not need an account for personal local use. Online features
			should explain what data leaves the device before they run.
		</p>
	</section>

	<section>
		<h2>Minors</h2>
		<p>
			Plural system tools can hold sensitive identity, journal, health-adjacent, and
			relationship data. Cloud accounts for younger users need separate safety and
			consent rules, not a normal signup flow.
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
		<h2>Sync later</h2>
		<p>
			Sync, friends, hosted backup, push notifications, and web login are planned as
			opt-in features. Local use should keep working without them.
		</p>
	</section>
</main>

<style>
	@import '../page.css';
</style>
