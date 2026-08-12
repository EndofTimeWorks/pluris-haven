import { readFile } from 'node:fs/promises';

const basePath = 'mobile/lib/l10n/app_en.arb';
const usPath = 'mobile/lib/l10n/app_en_US.arb';

const expectedUsOverrides = new Set([
  'accentColorLabel',
  'colorHexFieldLabel',
  'copyHexColorTooltip',
  'currentColorLabel',
  'customizeTitle',
  'groupsEmptyBody',
  'noDashboardShortcutsBody',
  'saveCancelled',
  'tagColourFieldLabel',
  'useCustomColorLabel',
]);

const [base, us] = await Promise.all(
  [basePath, usPath].map(async (path) =>
    JSON.parse(await readFile(new URL(`../${path}`, import.meta.url), 'utf8')),
  ),
);

const errors = [];
const usKeys = Object.keys(us).filter((key) => key !== '@@locale');

if (us['@@locale'] !== 'en_US') {
  errors.push(`${usPath} must declare @@locale as en_US.`);
}

for (const key of usKeys) {
  if (!(key in base)) {
    errors.push(`${usPath} contains unknown key ${key}.`);
  } else if (JSON.stringify(us[key]) === JSON.stringify(base[key])) {
    errors.push(`${usPath} duplicates ${key}; remove it so en_US inherits app_en.arb.`);
  }

  if (!expectedUsOverrides.has(key)) {
    errors.push(
      `${key} is not a reviewed US English override; add it to the check if intentional.`,
    );
  }
}

for (const key of expectedUsOverrides) {
  if (!(key in us)) {
    errors.push(`${usPath} is missing reviewed override ${key}.`);
  }
}

if (errors.length > 0) {
  console.error(errors.join('\n'));
  process.exitCode = 1;
} else {
  console.log(`Checked ${usKeys.length} intentional en_US overrides.`);
}
