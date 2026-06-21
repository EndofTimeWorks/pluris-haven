<svelte:head>
    <title>Pluris Haven</title>
    <meta name="description" content="Offline-first app for plural systems." />
</svelte:head>

<main>
    <header>
        <h1>Pluris Haven</h1>
        <p>Offline-first app for plural systems. No account needed.</p>
        <div class="badges">
            <span class="badge warn">pre-alpha</span>
            <span class="badge">Android</span>
        </div>
    </header>

    <section class="download">
        <h2>Get the app</h2>
        <p>
            Install via <a
                href="https://obtainium.imranr.dev"
                target="_blank"
                rel="noopener">Obtainium</a
            >
            (recommended) or grab the APK directly from GitHub Releases. Dev builds
            update automatically when new commits land.
        </p>
        <div class="actions">
            <a
                class="btn primary"
                href="https://github.com/EndofTimeWorks/pluris-haven/releases"
                target="_blank"
                rel="noopener"
            >
                Download APK
            </a>
            <a
                class="btn"
                href="https://github.com/EndofTimeWorks/pluris-haven"
                target="_blank"
                rel="noopener"
            >
                Source on GitHub
            </a>
        </div>

        <details class="obtainium-steps">
            <summary>How to add via Obtainium</summary>
            <ol>
                <li>Open Obtainium → Add App</li>
                <li>
                    Paste: <code
                        >https://github.com/EndofTimeWorks/pluris-haven</code
                    >
                </li>
                <li>Enable <strong>Include prereleases</strong></li>
                <li>Set asset filter to <code>pluris-haven-dev.apk</code></li>
                <li>Install and track future updates automatically</li>
            </ol>
        </details>
    </section>

    <section>
        <h2>What works right now</h2>
        <p>This is pre-alpha. Core features are in, but expect rough edges.</p>
        <ul>
            <li>Members, groups, custom fields</li>
            <li>Front tracking and front history</li>
            <li>Notes, journals, polls, chat, reminders</li>
            <li>
                Simply Plural import (members, fronts, groups, custom fields,
                avatars)
            </li>
            <li>PluralKit file import</li>
            <li>Local backup and restore</li>
            <li>Offline by default - data stays on device</li>
        </ul>
    </section>

    <section>
        <h2>What's not done yet</h2>
        <ul>
            <li>iOS</li>
            <li>Sync / friends / hosted backup</li>
            <li>Push notifications</li>
            <li>Web app</li>
        </ul>
    </section>

    <section>
        <h2>Privacy</h2>
        <p>
            Local data stays on your device. Any online feature shows a notice
            before connecting, what leaves, where it goes, and how to
            disconnect.
        </p>
    </section>

    <footer>
        <p>
            <a
                href="https://github.com/EndofTimeWorks/pluris-haven"
                target="_blank"
                rel="noopener">GitHub</a
            >
            ·
            <a
                href="https://github.com/EndofTimeWorks/pluris-haven/issues"
                target="_blank"
                rel="noopener">Issues</a
            >
            · Source-available, noncommercial
        </p>
    </footer>
</main>

<style>
    :global(body) {
        margin: 0;
        background: #0f0f13;
        color: #e8e4f0;
        font-family:
            ui-sans-serif,
            system-ui,
            -apple-system,
            BlinkMacSystemFont,
            "Segoe UI",
            sans-serif;
    }

    :global(*) {
        box-sizing: border-box;
    }

    main {
        max-width: 680px;
        margin: 0 auto;
        padding: 48px 20px 72px;
    }

    header {
        padding-bottom: 32px;
        border-bottom: 1px solid #2a2835;
    }

    h1 {
        margin: 0 0 8px;
        font-size: 1.9rem;
        font-weight: 800;
        letter-spacing: -0.02em;
        color: #f0ecff;
    }

    header p {
        margin: 0 0 14px;
        color: #9b96b0;
        font-size: 1rem;
    }

    .badges {
        display: flex;
        gap: 8px;
    }

    .badge {
        display: inline-block;
        padding: 3px 9px;
        border-radius: 99px;
        font-size: 0.75rem;
        font-weight: 600;
        background: #2a2835;
        color: #9b96b0;
        border: 1px solid #3a3650;
    }

    .badge.warn {
        background: #2a1f10;
        color: #d4a056;
        border-color: #5a3d10;
    }

    section {
        padding: 28px 0;
        border-bottom: 1px solid #2a2835;
    }

    h2 {
        margin: 0 0 10px;
        font-size: 1rem;
        font-weight: 700;
        color: #c8c0e0;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        font-size: 0.78rem;
    }

    p {
        margin: 0 0 16px;
        color: #9b96b0;
        line-height: 1.6;
        font-size: 0.95rem;
    }

    ul,
    ol {
        margin: 0;
        padding-left: 20px;
        color: #b8b2cc;
        line-height: 1.8;
        font-size: 0.95rem;
    }

    li {
        margin-bottom: 2px;
    }

    .download p {
        margin-bottom: 20px;
    }

    .actions {
        display: flex;
        gap: 10px;
        flex-wrap: wrap;
        margin-bottom: 20px;
    }

    .btn {
        display: inline-block;
        padding: 10px 20px;
        border-radius: 8px;
        font-size: 0.9rem;
        font-weight: 600;
        text-decoration: none;
        background: #2a2835;
        color: #c8c0e0;
        border: 1px solid #3a3650;
        transition: background 0.15s;
    }

    .btn:hover {
        background: #332f45;
    }

    .btn.primary {
        background: #5b3ff5;
        color: #fff;
        border-color: #5b3ff5;
    }

    .btn.primary:hover {
        background: #6b4fff;
    }

    .obtainium-steps {
        margin-top: 4px;
    }

    summary {
        cursor: pointer;
        color: #7b6faa;
        font-size: 0.88rem;
        user-select: none;
        list-style: none;
    }

    summary::before {
        content: "▸ ";
    }

    details[open] summary::before {
        content: "▾ ";
    }

    .obtainium-steps ol {
        margin-top: 12px;
        color: #9b96b0;
    }

    a {
        color: #a08fff;
        text-decoration: none;
    }

    a:hover {
        text-decoration: underline;
    }

    code {
        background: #1e1c2a;
        border: 1px solid #2a2835;
        border-radius: 4px;
        padding: 1px 6px;
        font-size: 0.85em;
        color: #c8c0e0;
    }

    strong {
        color: #d0c8e8;
        font-weight: 600;
    }

    footer {
        padding-top: 28px;
    }

    footer p {
        margin: 0;
        font-size: 0.85rem;
        color: #5a5570;
    }
</style>
