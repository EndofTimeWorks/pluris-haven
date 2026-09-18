#!/usr/bin/env node

import { execFileSync } from 'node:child_process';

const sectionOrder = [
  'Added',
  'Changed',
  'Fixed',
  'Security',
  'Performance',
  'Data & recovery',
  'Accessibility',
  'Developer / tooling',
];

function runGit(args) {
  return execFileSync('git', args, { encoding: 'utf8' }).trim();
}

function parseCommit(subject, body) {
  const match = /^(?<type>[a-z]+)(?:\((?<scope>[^)]+)\))?(?<breaking>!)?:\s+(?<title>.+)$/.exec(
    subject,
  );
  if (!match) return null;

  const { type, scope = '', breaking, title } = match.groups;
  const lowerScope = scope.toLowerCase();
  const isBreaking = Boolean(breaking) || /^BREAKING[ -]CHANGE:/im.test(body);
  let section;

  if (type === 'security' || lowerScope.includes('security')) section = 'Security';
  else if (type === 'perf') section = 'Performance';
  else if (lowerScope.match(/archive|backup|import|migration|recovery|data/))
    section = 'Data & recovery';
  else if (lowerScope.match(/a11y|accessibility/)) section = 'Accessibility';
  else if (type === 'feat') section = 'Added';
  else if (type === 'fix') section = 'Fixed';
  else if (type === 'revert') section = 'Changed';
  else if (['build', 'refactor'].includes(type)) section = 'Developer / tooling';
  else return null;

  return { section, title: isBreaking ? `**Breaking:** ${title}` : title };
}

export function renderReleaseNotes(commits) {
  const sections = new Map(sectionOrder.map((section) => [section, []]));
  for (const commit of commits) {
    const parsed = parseCommit(commit.subject, commit.body);
    if (parsed) sections.get(parsed.section).push(parsed.title);
  }

  const rendered = sectionOrder.flatMap((section) => {
    const entries = sections.get(section);
    return entries.length === 0
      ? []
      : [`### ${section}`, '', ...entries.map((entry) => `- ${entry}`), ''];
  });

  return rendered.length === 0
    ? 'No user-facing changes in this range.\n'
    : `${rendered.join('\n').trimEnd()}\n`;
}

export function generateReleaseNotes({ from, to }) {
  const range = from ? `${from}..${to}` : to;
  const output = runGit(['log', '--reverse', '--format=%s%x1f%b%x1e', range]);
  if (!output) return renderReleaseNotes([]);

  const commits = output
    .split('\x1e')
    .filter(Boolean)
    .map((record) => {
      const [subject, body = ''] = record.split('\x1f');
      return { subject, body };
    });
  return renderReleaseNotes(commits);
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  const args = process.argv.slice(2);
  const fromIndex = args.indexOf('--from');
  const toIndex = args.indexOf('--to');
  const from = fromIndex === -1 ? undefined : args[fromIndex + 1];
  const to = toIndex === -1 ? undefined : args[toIndex + 1];
  if (!to || (fromIndex !== -1 && !from)) {
    console.error('Usage: generate-release-notes.mjs [--from <revision>] --to <revision>');
    process.exit(1);
  }
  process.stdout.write(generateReleaseNotes({ from, to }));
}
