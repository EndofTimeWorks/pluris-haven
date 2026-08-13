import { readdir, readFile } from 'node:fs/promises';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const sourceRoot = fileURLToPath(new URL('../mobile/lib/features/', import.meta.url));
const failures = [];
const technicalLiteral = /^(?:#[0-9A-Fa-f]{6}|https?:\/\/|PH$|\d{2}$|>$)/;
const patterns = [
  /(?:const\s+)?Text\(\s*(['"])([^'"\n]+)\1/g,
  /\b(?:title|subtitle|tooltip|labelText|helperText|hintText|semanticLabel|body|message):\s*(['"])([^'"\n]+)\1/g,
  /SpSettingsRow\(\s*(['"])([^'"\n]+)\1/g,
];

async function dartFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) files.push(...(await dartFiles(path)));
    if (entry.isFile() && entry.name.endsWith('.dart')) files.push(path);
  }
  return files;
}

for (const path of await dartFiles(sourceRoot)) {
  const source = await readFile(path, 'utf8');
  for (const pattern of patterns) {
    for (const match of source.matchAll(pattern)) {
      const value = match[2].trim();
      if (!value || technicalLiteral.test(value) || value === 'pk;token' || value.includes('$'))
        continue;
      const line = source.slice(0, match.index).split('\n').length;
      failures.push(`${relative(sourceRoot, path)}:${line}: ${value}`);
    }
  }
}

if (failures.length) {
  console.error('User-facing literals must come from app_en.arb:\n' + failures.join('\n'));
  process.exitCode = 1;
} else {
  console.log('No hardcoded user-facing literals found in mobile feature widgets.');
}
