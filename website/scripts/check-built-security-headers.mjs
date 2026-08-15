import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const headersPath = fileURLToPath(new URL('../build/_headers', import.meta.url));
const headers = await readFile(headersPath, 'utf8');

const requiredValues = [
  "default-src 'self'",
  "base-uri 'self'",
  "frame-ancestors 'none'",
  "object-src 'none'",
  "script-src 'self'",
  "connect-src 'self'",
  'X-Content-Type-Options: nosniff',
  'X-Frame-Options: DENY',
  'Referrer-Policy: no-referrer',
  'Strict-Transport-Security: max-age=31536000; includeSubDomains',
];

const missing = requiredValues.filter((value) => !headers.includes(value));
if (missing.length) {
  console.error(`Website security headers are missing: ${missing.join(', ')}`);
  process.exitCode = 1;
} else {
  console.log('Website security-header contract passed.');
}
