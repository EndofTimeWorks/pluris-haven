part of 'home_page.dart';

class AppOptionsPage extends StatelessWidget {
  const AppOptionsPage({
    super.key,
    required this.customization,
    required this.repository,
  });

  final AppCustomization customization;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return SpPage(
      children: [
        SpSettingsGroup(
          title: 'Customize',
          rows: [
            SpSettingsRow(
              'Theme',
              customization.themeMode.label,
              onTap: () => repository.setThemeMode(
                _nextThemeMode(customization.themeMode),
              ),
            ),
            SpSettingsRow(
              'Accent color',
              customization.accentLabel,
              trailing: AccentSwatch(
                color: Color(customization.effectiveAccentArgb),
              ),
              onTap: () => showAccentPicker(
                context,
                customization: customization,
                repository: repository,
              ),
            ),
            SpSwitchRow(
              title: 'Compact dashboard',
              subtitle: 'smaller shortcuts, more room',
              value: customization.compactDashboard,
              onChanged: repository.setCompactDashboard,
            ),
            SpSwitchRow(
              title: 'Dashboard subtitles',
              subtitle: 'show counts under shortcuts',
              value: customization.showDashboardSubtitles,
              onChanged: repository.setShowDashboardSubtitles,
            ),
            SpSettingsRow(
              'Language',
              customization.language.label,
              key: const ValueKey('language-setting-row'),
              onTap: () => showLanguagePicker(
                context,
                selectedCode: customization.languageCode,
                repository: repository,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DashboardShortcutManager(
          customization: customization,
          repository: repository,
        ),
        const SizedBox(height: 12),
        const SpSettingsGroup(
          title: 'Local defaults',
          rows: [
            SpSettingsRow('Security', 'device storage'),
            SpSettingsRow('Sync', 'off by default'),
            SpSettingsRow('Accessibility', 'default sizing'),
          ],
        ),
      ],
    );
  }

  HavenThemeMode _nextThemeMode(HavenThemeMode current) {
    return switch (current) {
      HavenThemeMode.dark => HavenThemeMode.light,
      HavenThemeMode.light => HavenThemeMode.system,
      HavenThemeMode.system => HavenThemeMode.dark,
    };
  }
}

void showAccentPicker(
  BuildContext context, {
  required AppCustomization customization,
  required HavenRepository repository,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) =>
        AccentPickerSheet(customization: customization, repository: repository),
  );
}

class AccentPickerSheet extends StatefulWidget {
  const AccentPickerSheet({
    super.key,
    required this.customization,
    required this.repository,
  });

  final AppCustomization customization;
  final HavenRepository repository;

  @override
  State<AccentPickerSheet> createState() => _AccentPickerSheetState();
}

class _AccentPickerSheetState extends State<AccentPickerSheet> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.customization.customAccentHex ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Accent color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final accent in HavenAccentColor.values)
                  ChoiceChip(
                    label: Text(accent.label),
                    selected:
                        widget.customization.customAccentHex == null &&
                        widget.customization.accentColor == accent,
                    avatar: AccentSwatch(color: Color(accent.argb)),
                    onSelected: (_) async {
                      await widget.repository.setAccentColor(accent);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                if (widget.customization.customAccentHex != null)
                  ChoiceChip(
                    label: Text(
                      'Custom ${widget.customization.customAccentHex!.toUpperCase()}',
                    ),
                    selected: true,
                    avatar: AccentSwatch(
                      color: Color(widget.customization.effectiveAccentArgb),
                    ),
                    onSelected: (_) {},
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('custom-accent-hex-field'),
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Custom hex',
                hintText: '#7B61FF',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('save-custom-accent-button'),
              onPressed: _save,
              icon: const Icon(Icons.palette_rounded),
              label: const Text('Use custom color'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    final normalized = _normalizeUiHexColor(text);
    if (normalized == null) {
      setState(() => _error = 'Use 6 hex digits, like #7B61FF.');
      return;
    }
    await widget.repository.setCustomAccentColor(normalized);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

String? _normalizeUiHexColor(String value) {
  final trimmed = value.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(trimmed)) {
    return null;
  }
  return '#${trimmed.toUpperCase()}';
}

void showLanguagePicker(
  BuildContext context, {
  required String selectedCode,
  required HavenRepository repository,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _spSurface,
    builder: (context) =>
        LanguagePickerSheet(selectedCode: selectedCode, repository: repository),
  );
}

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({
    super.key,
    required this.selectedCode,
    required this.repository,
  });

  final String selectedCode;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          const Text(
            'Choose your language',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Interface text stays English until translations are added.',
            style: TextStyle(color: _spMuted, height: 1.35),
          ),
          const SizedBox(height: 14),
          for (final language in supportedLanguages)
            SpLanguageOption(
              key: ValueKey('language-option-${language.code}'),
              language: language,
              selected: language.code == selectedCode,
              onTap: () async {
                await repository.setLanguageCode(language.code);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
    );
  }
}

class SpLanguageOption extends StatelessWidget {
  const SpLanguageOption({
    super.key,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final SupportedLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? _spLine : _spCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              language.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              language.code,
              style: const TextStyle(color: _spMuted),
            ),
            trailing: selected
                ? Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class DashboardShortcutManager extends StatelessWidget {
  const DashboardShortcutManager({
    super.key,
    required this.customization,
    required this.repository,
  });

  final AppCustomization customization;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final activeIds = customization.dashboardShortcutIds;
    final rows = <Widget>[
      for (final shortcut in _orderedShortcutDefinitions(activeIds))
        DashboardShortcutRow(
          shortcut: shortcut,
          visible: activeIds.contains(shortcut.id),
          canMoveUp: activeIds.indexOf(shortcut.id) > 0,
          canMoveDown:
              activeIds.contains(shortcut.id) &&
              activeIds.indexOf(shortcut.id) < activeIds.length - 1,
          onVisibleChanged: (visible) =>
              repository.setDashboardShortcutVisible(shortcut.id, visible),
          onMoveUp: () => repository.moveDashboardShortcut(shortcut.id, -1),
          onMoveDown: () => repository.moveDashboardShortcut(shortcut.id, 1),
        ),
      DashboardResetRow(onReset: repository.resetDashboardShortcuts),
    ];

    return SpSettingsGroup(title: 'Dashboard shortcuts', rows: rows);
  }

  List<DashboardShortcutDefinition> _orderedShortcutDefinitions(
    List<String> activeIds,
  ) {
    final definitions = {for (final item in dashboardShortcuts) item.id: item};
    final ordered = <DashboardShortcutDefinition>[
      for (final id in activeIds) ?definitions.remove(id),
      ...definitions.values,
    ];
    return ordered;
  }
}

class DashboardShortcutRow extends StatelessWidget {
  const DashboardShortcutRow({
    super.key,
    required this.shortcut,
    required this.visible,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onVisibleChanged,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final DashboardShortcutDefinition shortcut;
  final bool visible;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<bool> onVisibleChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          SpIconBubble(
            icon: shortcut.icon,
            color: visible ? _spGold : _spMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortcut.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  visible ? 'shown on dashboard' : 'hidden',
                  style: const TextStyle(color: _spMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('shortcut-up-${shortcut.id}'),
            tooltip: 'Move up',
            onPressed: visible && canMoveUp ? onMoveUp : null,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
          IconButton(
            key: ValueKey('shortcut-down-${shortcut.id}'),
            tooltip: 'Move down',
            onPressed: visible && canMoveDown ? onMoveDown : null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          Switch(
            key: ValueKey('shortcut-visible-${shortcut.id}'),
            value: visible,
            onChanged: onVisibleChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class DashboardResetRow extends StatelessWidget {
  const DashboardResetRow({super.key, required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SpSettingsRow(
      'Reset dashboard',
      'restore default shortcut order',
      trailing: const Icon(Icons.restart_alt_rounded, color: _spMuted),
      onTap: onReset,
    );
  }
}
