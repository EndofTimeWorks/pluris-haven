import assert from 'node:assert/strict';
import test from 'node:test';

import { generateReleaseNotes, renderReleaseNotes } from './generate-release-notes.mjs';

test('renders deterministic user-facing release note categories', () => {
  const notes = renderReleaseNotes([
    { subject: 'feat(mobile): add archive labels', body: '' },
    { subject: 'fix(backup): recover interrupted uploads', body: '' },
    { subject: 'security(server): validate forwarded hosts', body: '' },
    { subject: 'perf: reduce import allocations', body: '' },
    { subject: 'refactor(tooling): simplify release checks', body: '' },
    { subject: 'docs: update contributor wording', body: '' },
    { subject: 'ci: refresh workflow runner', body: '' },
    { subject: 'feat(api)!: remove legacy endpoint', body: '' },
    { subject: 'revert: restore local sync behaviour', body: '' },
  ]);

  assert.equal(
    notes,
    `### Added\n\n- add archive labels\n- **Breaking:** remove legacy endpoint\n\n### Changed\n\n- restore local sync behaviour\n\n### Security\n\n- validate forwarded hosts\n\n### Performance\n\n- reduce import allocations\n\n### Data & recovery\n\n- recover interrupted uploads\n\n### Developer / tooling\n\n- simplify release checks\n`,
  );
});

test('reports an intentionally empty user-facing range', () => {
  assert.equal(
    renderReleaseNotes([{ subject: 'ci: refresh workflow runner', body: '' }]),
    'No user-facing changes in this range.\n',
  );
});

test('reads every conventional commit from real git-log record separators', () => {
  const notes = generateReleaseNotes({
    from: 'previous',
    to: 'current',
    runGitCommand: () =>
      'fix(mobile): keep settings after unlock\x1f\x1e\nfeat(import): restore OpenPlural archives\x1f\x1e\n',
  });
  assert.match(notes, /### Data & recovery/);
  assert.match(notes, /- restore OpenPlural archives/);
  assert.match(notes, /### Fixed/);
  assert.match(notes, /- keep settings after unlock/);
});
