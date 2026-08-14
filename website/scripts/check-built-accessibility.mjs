import { readdir, readFile } from 'node:fs/promises';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const buildDirectory = fileURLToPath(new URL('../build/', import.meta.url));
const failures = [];

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

function count(html, pattern) {
  return [...html.matchAll(pattern)].length;
}

function attribute(tag, name) {
  const match = tag.match(new RegExp(`\\s${name}=(?:"([^"]*)"|'([^']*)')`, 'i'));
  return match?.[1] ?? match?.[2] ?? null;
}

function visibleText(fragment) {
  return fragment
    .replace(/<[^>]+aria-hidden=(?:"true"|'true')[^>]*>[\s\S]*?<\/[^>]+>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&(?:nbsp|#160);/gi, ' ')
    .replace(/&[^;]+;/g, 'x')
    .replace(/\s+/g, ' ')
    .trim();
}

for (const path of await htmlFiles(buildDirectory)) {
  const html = await readFile(path, 'utf8');
  const page = relative(buildDirectory, path);
  const fail = (message) => failures.push(`${page}: ${message}`);

  if (!/<html\b[^>]*\blang=(?:"[^"]+"|'[^']+')/i.test(html)) {
    fail('the html element needs a non-empty lang attribute');
  }
  if (!/<title>\s*[^<\s][^<]*<\/title>/i.test(html)) {
    fail('the page needs a non-empty title');
  }
  if (/\bclass=(?:"[^"]*\bno-js\b[^"]*"|'[^']*\bno-js\b[^']*')/i.test(html)) {
    fail('the no-js class makes the skip link permanently visible');
  }
  if (
    !/<a\b[^>]*\bclass=(?:"[^"]*\bskip-link\b[^"]*"|'[^']*\bskip-link\b[^']*')[^>]*\bhref=(?:"#main-content"|'#main-content')/i.test(
      html,
    )
  ) {
    fail('the page needs a skip link targeting #main-content');
  }
  if (count(html, /<main\b/gi) !== 1) fail('expected exactly one main landmark');
  if (count(html, /<h1\b/gi) !== 1) fail('expected exactly one h1');
  if (/\btabindex=(?:"[1-9][0-9]*"|'[1-9][0-9]*')/i.test(html)) {
    fail('positive tabindex changes the natural keyboard order');
  }

  const ids = [...html.matchAll(/\sid=(?:"([^"]+)"|'([^']+)')/gi)].map(
    (match) => match[1] ?? match[2],
  );
  const duplicateIds = [...new Set(ids.filter((id, index) => ids.indexOf(id) !== index))];
  if (duplicateIds.length) fail(`duplicate ids: ${duplicateIds.join(', ')}`);

  for (const match of html.matchAll(/<a\b[^>]*href=(?:"#([^"]+)"|'#([^']+)')[^>]*>/gi)) {
    const target = match[1] ?? match[2];
    if (!ids.includes(target)) fail(`fragment link #${target} has no target`);
  }

  let previousHeading = 0;
  for (const match of html.matchAll(/<h([1-6])\b/gi)) {
    const level = Number(match[1]);
    if (previousHeading && level > previousHeading + 1) {
      fail(`heading level jumps from h${previousHeading} to h${level}`);
    }
    previousHeading = level;
  }

  for (const match of html.matchAll(/<img\b[^>]*>/gi)) {
    if (attribute(match[0], 'alt') === null) fail('image is missing alt text');
  }

  for (const match of html.matchAll(/<(a|button)\b([^>]*)>([\s\S]*?)<\/\1>/gi)) {
    const tag = `<${match[1]}${match[2]}>`;
    const name = attribute(tag, 'aria-label') ?? attribute(tag, 'title');
    if (!name?.trim() && !visibleText(match[3])) {
      fail(`${match[1].toLowerCase()} has no accessible name`);
    }
  }

  for (const match of html.matchAll(/<(input|select|textarea)\b[^>]*>/gi)) {
    const tag = match[0];
    const id = attribute(tag, 'id');
    const labelled =
      Boolean(attribute(tag, 'aria-label')?.trim()) ||
      Boolean(attribute(tag, 'aria-labelledby')?.trim()) ||
      Boolean(id && new RegExp(`<label\\b[^>]*\\bfor=(?:"${id}"|'${id}')`, 'i').test(html));
    if (!labelled && attribute(tag, 'type') !== 'hidden') {
      fail(`${match[1].toLowerCase()} has no associated label`);
    }
  }
}

if (failures.length) {
  console.error(failures.join('\n'));
  process.exitCode = 1;
} else {
  console.log('Website accessibility contract passed for every generated HTML page.');
}
