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

## SSH deploy

The repository includes a GitHub Actions deployment workflow. After a successful
`CI` run on `main`, it can connect over SSH, pull the exact fast-forward update,
install the locked website dependencies, and rebuild the static site.

Configure these repository Actions secrets before enabling it:

- `WEBSITE_DEPLOY_HOST`
- `WEBSITE_DEPLOY_USER`
- `WEBSITE_DEPLOY_KEY`
- `WEBSITE_DEPLOY_KNOWN_HOSTS`
- `WEBSITE_DEPLOY_PATH` (optional; defaults to `/srv/pluris-haven`)

The SSH key should be restricted to the deployment account and the known-hosts
value should be generated from the intended host out of band. The host must
already have repository access for `git pull`, Node.js, pnpm, and the static
web-server configuration.

The equivalent manual commands on the host are:

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
