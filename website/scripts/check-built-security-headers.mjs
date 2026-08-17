import { readdir, readFile } from 'node:fs/promises';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const buildDirectory = fileURLToPath(new URL('../build/', import.meta.url));
const headersPath = join(buildDirectory, '_headers');
const headers = await readFile(headersPath, 'utf8');

const requiredHeaders = [
  'X-Content-Type-Options: nosniff',
  'X-Frame-Options: DENY',
  'Referrer-Policy: no-referrer',
  'Strict-Transport-Security: max-age=31536000; includeSubDomains',
];

const failures = requiredHeaders
  .filter((value) => !headers.includes(value))
  .map((value) => `_headers: missing ${value}`);

async function htmlFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) files.push(...(await htmlFiles(path)));
    if (entry.isFile() && entry.name.endsWith('.html')) files.push(path);
  }
  return files;
}

const requiredPolicy = [
  "default-src 'self'",
  "base-uri 'self'",
  "form-action 'none'",
  "object-src 'none'",
  "script-src 'self'",
  "connect-src 'self'",
];

for (const path of await htmlFiles(buildDirectory)) {
  const html = await readFile(path, 'utf8');
  const page = relative(buildDirectory, path);
  const meta = html.match(
    /<meta\s+http-equiv="content-security-policy"\s+content="([^"]+)"\s*\/?\s*>/i,
  );
  if (meta === null) {
    failures.push(`${page}: missing generated CSP`);
    continue;
  }
  for (const directive of requiredPolicy) {
    if (!meta[1].includes(directive)) failures.push(`${page}: CSP missing ${directive}`);
  }
  if (/<script\b/i.test(html) && !/script-src[^;]*'sha256-[^']+'/.test(meta[1])) {
    failures.push(`${page}: CSP does not authenticate the hydration script`);
  }
}

if (failures.length) {
  console.error(failures.join('\n'));
  process.exitCode = 1;
} else {
  console.log('Website security-header and CSP contract passed.');
}
