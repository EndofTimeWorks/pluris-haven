enum ImportInputKind {
  file('File'),
  liveToken('Live token'),
  encryptedFile('Encrypted file');

  const ImportInputKind(this.label);

  final String label;
}

enum ImporterStatus {
  planned('planned'),
  next('next'),
  ready('ready'),
  readyShape('shape ready');

  const ImporterStatus(this.label);

  final String label;
}

enum ImportConflictStrategy {
  prompt('prompt', 'Ask for each match'),
  create('create', 'Create new records'),
  skip('skip', 'Skip existing matches'),
  update('update', 'Update existing matches');

  const ImportConflictStrategy(this.storageValue, this.label);

  final String storageValue;
  final String label;
}

enum ImportSource {
  plurisHavenArchive(
    label: 'Pluris Haven archive',
    subtitle: 'Local JSON backup exported from this app',
    inputKinds: [ImportInputKind.file],
    status: ImporterStatus.ready,
    dedupeKeys: ['local IDs', 'PluralKit IDs', 'normalized names'],
  ),
  simplyPlural(
    label: 'Simply Plural',
    subtitle: 'JSON export or backup archive',
    inputKinds: [ImportInputKind.file],
    status: ImporterStatus.ready,
    dedupeKeys: ['Simply Plural IDs', 'PluralKit IDs', 'normalized names'],
  ),
  pluralKitFile(
    label: 'PluralKit file',
    subtitle: 'PK export with members, groups, and switches',
    inputKinds: [ImportInputKind.file],
    status: ImporterStatus.ready,
    dedupeKeys: ['PluralKit UUIDs', 'PluralKit short IDs', 'normalized names'],
  ),
  pluralKitLive(
    label: 'PluralKit live',
    subtitle: 'Import with pk;token, then support bidirectional sync later',
    inputKinds: [ImportInputKind.liveToken],
    status: ImporterStatus.readyShape,
    dedupeKeys: ['PluralKit UUIDs', 'PluralKit short IDs'],
  ),
  tupperbox(
    label: 'Tupperbox',
    subtitle: 'Tupper roster export',
    inputKinds: [ImportInputKind.file],
    status: ImporterStatus.ready,
    dedupeKeys: ['Tupperbox IDs', 'normalized names'],
  ),
  pluralSpace(
    label: 'PluralSpace',
    subtitle: 'PluralSpace export',
    inputKinds: [ImportInputKind.file],
    status: ImporterStatus.ready,
    dedupeKeys: ['PluralSpace IDs', 'normalized names'],
  ),
  prism(
    label: 'Prism',
    subtitle: 'Encrypted .prism export',
    inputKinds: [ImportInputKind.encryptedFile],
    status: ImporterStatus.planned,
    dedupeKeys: ['Prism IDs', 'normalized names'],
  );

  const ImportSource({
    required this.label,
    required this.subtitle,
    required this.inputKinds,
    required this.status,
    required this.dedupeKeys,
  });

  final String label;
  final String subtitle;
  final List<ImportInputKind> inputKinds;
  final ImporterStatus status;
  final List<String> dedupeKeys;

  String get jobSource => switch (this) {
    ImportSource.plurisHavenArchive => 'plurishaven_archive',
    ImportSource.simplyPlural => 'simplyplural_file',
    ImportSource.pluralKitFile => 'pluralkit_file',
    ImportSource.pluralKitLive => 'pluralkit_api',
    ImportSource.tupperbox => 'tupperbox_file',
    ImportSource.pluralSpace => 'pluralspace_file',
    ImportSource.prism => 'prism_file',
  };

  String get inputLabel => inputKinds.map((kind) => kind.label).join(' + ');

  String get dedupeLabel => dedupeKeys.join(', ');
}

class PluralKitLiveImportShape {
  const PluralKitLiveImportShape();

  String get authHeaderName => 'Authorization';

  String get systemEndpoint => '/systems/@me';

  String get membersEndpoint => '/systems/@me/members';

  String get groupsEndpoint => '/systems/@me/groups?with_members=true';

  String get switchesEndpoint => '/systems/@me/switches?limit=100';

  Duration get pageDelay => const Duration(milliseconds: 600);

  List<String> get firstImportSteps => const [
    'Validate token with GET /systems/@me',
    'Fetch members from GET /systems/@me/members',
    'Fetch groups from GET /systems/@me/groups?with_members=true',
    'Page switches from GET /systems/@me/switches?limit=100',
    'Convert switches to local front intervals',
    'Stage dedupe review before writing records',
  ];
}
