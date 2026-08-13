# Pluris Haven website

Static SvelteKit site for Pluris Haven. It is meant to be pulled and built on a
server, then served from `website/build`.

## Commands

```sh
pnpm install --frozen-lockfile
pnpm check
pnpm build
pnpm preview
```

## Pull-only deploy

Use this shape on the host:

```sh
cd /srv/pluris-haven
git pull --ff-only
cd website
pnpm install --frozen-lockfile
pnpm build
```

Point nginx, Caddy, or another static file server at:

```text
/srv/pluris-haven/website/build
```

The build uses `@sveltejs/adapter-static` with precompressed `.gz` and `.br`
files. Configure the web server to serve those compressed files when supported.
It also publishes a `_headers` file for static hosts that recognise that
convention. For nginx, Caddy, or another generic server, configure the same
response headers at the server layer; serving `_headers` as a normal file does
not enable them.

## Routes

- `/` project overview
- `/download` Android build and Obtainium notes
- `/docs` import and hosting notes
- `/changelog` current pre-alpha status
- `/support` issues and optional funding links
- `/privacy` privacy and minors safety notes
- `/terms` working terms draft
- `/app` placeholder for the future web UI

## Before enabling hosted accounts

Do not open public signups until the privacy, terms, age/consent, deletion,
export, abuse, and sync-retention rules are written and linked from the app.
