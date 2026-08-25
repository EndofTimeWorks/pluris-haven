part of 'home_page.dart';

class AppOptionsPage extends StatelessWidget {
  const AppOptionsPage({
    super.key,
    required this.snapshot,
    required this.customization,
    required this.repository,
  });

  final HomeSnapshot? snapshot;
  final AppCustomization customization;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SpPage(
      children: [
        SpSettingsGroup(
          title: l10n.customizeTitle,
          rows: [
            SpSettingsRow(
              l10n.themeRowTitle,
              customization.themeMode.label,
              onTap: () => repository.setThemeMode(
                _nextThemeMode(customization.themeMode),
              ),
            ),
            SpSettingsRow(
              l10n.visualThemeRowTitle,
              customization.visualTheme.label,
              onTap: () => showVisualThemePicker(
                context,
                customization: customization,
                repository: repository,
              ),
            ),
            SpSettingsRow(
              l10n.accentColorLabel,
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
            SpSettingsRow(
              l10n.appearanceTitle,
              l10n.appearanceSubtitle,
              onTap: () => showAppearanceEditor(
                context,
                customization: customization,
                repository: repository,
              ),
            ),
            SpSwitchRow(
              title: l10n.compactDashboardTitle,
              subtitle: l10n.compactDashboardSubtitle,
              value: customization.compactDashboard,
              onChanged: repository.setCompactDashboard,
            ),
            SpSwitchRow(
              title: l10n.dashboardSubtitlesTitle,
              subtitle: l10n.dashboardSubtitlesSubtitle,
              value: customization.showDashboardSubtitles,
              onChanged: repository.setShowDashboardSubtitles,
            ),
            SpSettingsRow(
              l10n.languageRowTitle,
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
        SpSettingsGroup(
          title: l10n.accessibilityGroupTitle,
          rows: [
            if (NotificationService.instance.setupFailed)
              SpSettingsRow(
                l10n.notificationsUnavailableTitle,
                l10n.notificationsUnavailableBody,
              ),
            SpSwitchRow(
              title: l10n.reducedMotionTitle,
              subtitle: l10n.reducedMotionSubtitle,
              value: customization.reducedMotion,
              onChanged: repository.setReducedMotion,
            ),
            SpSwitchRow(
              title: l10n.frontingNotificationTitle,
              subtitle: l10n.frontingNotificationSubtitle,
              value: customization.frontStatusNotification,
              onChanged: (enabled) async {
                await repository.setFrontStatusNotification(enabled);
                if (!enabled) {
                  await NotificationService.instance
                      .cancelFrontStatusNotification();
                }
              },
            ),
            if (customization.frontStatusNotification &&
                defaultTargetPlatform == TargetPlatform.android) ...[
              SpSwitchRow(
                title: l10n.frontStatusShowOnLockScreenTitle,
                subtitle: l10n.frontStatusShowOnLockScreenSubtitle,
                value: customization.frontStatusShowOnLockScreen,
                onChanged: (value) async {
                  await repository.setFrontStatusShowOnLockScreen(value);
                  if (context.mounted) {
                    await _refreshFrontStatusNotification(context);
                  }
                },
              ),
              SpSwitchRow(
                title: l10n.frontStatusRevealMemberNameTitle,
                subtitle: l10n.frontStatusRevealMemberNameSubtitle,
                value: customization.frontStatusRevealMemberName,
                onChanged: (value) async {
                  await repository.setFrontStatusRevealMemberName(value);
                  if (context.mounted) {
                    await _refreshFrontStatusNotification(context);
                  }
                },
              ),
            ],
            SpSwitchRow(
              title: l10n.appLockTitle,
              subtitle: l10n.appLockSubtitle,
              value: customization.appLockEnabled,
              onChanged: repository.setAppLockEnabled,
            ),
            SpSwitchRow(
              title: defaultTargetPlatform == TargetPlatform.iOS
                  ? l10n.iosPrivacyScreenTitle
                  : l10n.screenshotBlockingTitle,
              subtitle: defaultTargetPlatform == TargetPlatform.iOS
                  ? l10n.iosPrivacyScreenSubtitle
                  : l10n.screenshotBlockingSubtitle,
              value: customization.screenshotBlockingEnabled,
              onChanged: repository.setScreenshotBlockingEnabled,
            ),
            SpSwitchRow(
              title: l10n.highContrastTitle,
              subtitle: l10n.highContrastSubtitle,
              value: customization.highContrast,
              onChanged: repository.setHighContrast,
            ),
            SpSwitchRow(
              title: l10n.largerAppTextTitle,
              subtitle: l10n.largerAppTextSubtitle,
              value: customization.largeText,
              onChanged: repository.setLargeText,
            ),
            SpSwitchRow(
              title: l10n.compactListsTitle,
              subtitle: l10n.compactListsSubtitle,
              value: customization.compactLists,
              onChanged: repository.setCompactLists,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DashboardShortcutManager(
          customization: customization,
          repository: repository,
        ),
        const SizedBox(height: 12),
        SpSettingsGroup(
          title: l10n.localDefaultsTitle,
          rows: [
            SpSettingsRow(l10n.securityRowTitle, l10n.securityRowValue),
            SpSettingsRow(l10n.syncRowTitle, l10n.syncRowValue),
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

  Future<void> _refreshFrontStatusNotification(BuildContext context) async {
    final frontLabel = snapshot?.currentFrontLabel?.trim();
    if (frontLabel == null || frontLabel.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final updated = await repository.loadCustomization();
    await NotificationService.instance.showFrontStatusNotification(
      frontLabel: frontLabel,
      copy: _notificationCopy(l10n),
      showOnLockScreen: updated.frontStatusShowOnLockScreen,
      revealMemberName: updated.frontStatusRevealMemberName,
    );
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
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) =>
        AccentPickerSheet(customization: customization, repository: repository),
  );
}

void showAppearanceEditor(
  BuildContext context, {
  required AppCustomization customization,
  required HavenRepository repository,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => AppearanceEditorSheet(
      customization: customization,
      repository: repository,
    ),
  );
}

class AppearanceEditorSheet extends StatefulWidget {
  const AppearanceEditorSheet({
    super.key,
    required this.customization,
    required this.repository,
  });

  final AppCustomization customization;
  final HavenRepository repository;

  @override
  State<AppearanceEditorSheet> createState() => _AppearanceEditorSheetState();
}

class _AppearanceEditorSheetState extends State<AppearanceEditorSheet> {
  late final List<TextEditingController> _colors;
  late double _radius;
  late double _scale;
  String? _error;

  @override
  void initState() {
    super.initState();
    final appearance = widget.customization.appearance;
    _colors = [
      appearance.backgroundHex,
      appearance.surfaceHex,
      appearance.cardHex,
      appearance.textHex,
      appearance.mutedTextHex,
      appearance.outlineHex,
    ].map((value) => TextEditingController(text: value ?? '')).toList();
    _radius = appearance.cardRadius ?? 12;
    _scale = appearance.textScale ?? 1;
  }

  @override
  void dispose() {
    for (final controller in _colors) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.backgroundColorLabel,
      l10n.surfaceColorLabel,
      l10n.cardColorLabel,
      l10n.textColorLabel,
      l10n.mutedTextColorLabel,
      l10n.outlineColorLabel,
    ];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          Text(
            l10n.appearanceTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          for (var index = 0; index < _colors.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: _colors[index],
                decoration: InputDecoration(
                  labelText: labels[index],
                  hintText: '#RRGGBB',
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(l10n.cornerRadiusLabel),
          Slider(
            value: _radius,
            min: 0,
            max: 32,
            divisions: 32,
            label: _radius.round().toString(),
            onChanged: (value) => setState(() => _radius = value),
          ),
          Text(l10n.textScaleLabel),
          Slider(
            value: _scale,
            min: .8,
            max: 1.6,
            divisions: 8,
            label: _scale.toStringAsFixed(1),
            onChanged: (value) => setState(() => _scale = value),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: _save,
            child: Text(l10n.saveAppearanceButton),
          ),
          TextButton(onPressed: _reset, child: Text(l10n.appearanceReset)),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final colors = _colors.map((controller) => controller.text.trim()).toList();
    if (colors.any(
      (color) => color.isNotEmpty && _normalizeUiHexColor(color) == null,
    )) {
      setState(() => _error = AppLocalizations.of(context).hexDigitsErrorText);
      return;
    }
    await widget.repository.setAppearanceOverrides(
      HavenAppearanceOverrides(
        backgroundHex: _normalizeUiHexColor(colors[0]),
        surfaceHex: _normalizeUiHexColor(colors[1]),
        cardHex: _normalizeUiHexColor(colors[2]),
        textHex: _normalizeUiHexColor(colors[3]),
        mutedTextHex: _normalizeUiHexColor(colors[4]),
        outlineHex: _normalizeUiHexColor(colors[5]),
        cardRadius: _radius,
        textScale: _scale,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _reset() async {
    await widget.repository.setAppearanceOverrides(
      const HavenAppearanceOverrides(),
    );
    if (mounted) Navigator.pop(context);
  }
}

void showVisualThemePicker(
  BuildContext context, {
  required AppCustomization customization,
  required HavenRepository repository,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final theme in HavenVisualTheme.values)
            ListTile(
              leading: Icon(
                customization.visualTheme == theme
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(theme.label),
              onTap: () async {
                await repository.setVisualTheme(theme);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
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
            Text(
              l10n.accentColorLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                      l10n.customAccentChipLabel(
                        widget.customization.customAccentHex!.toUpperCase(),
                      ),
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
            SpCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AccentSwatch(
                    color: Color(widget.customization.effectiveAccentArgb),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.currentColorLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        SelectableText(
                          _currentHex,
                          key: const ValueKey('current-accent-hex'),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('copy-accent-hex-button'),
                    tooltip: l10n.copyHexColorTooltip,
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: _currentHex)),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('custom-accent-hex-field'),
              controller: _controller,
              decoration: InputDecoration(
                labelText: l10n.customHexFieldLabel,
                hintText: '#7B61FF',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('save-custom-accent-button'),
              onPressed: _save,
              icon: const Icon(Icons.palette_rounded),
              label: Text(l10n.useCustomColorLabel),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('clear-custom-accent-button'),
              onPressed: widget.customization.customAccentHex == null
                  ? null
                  : _clearCustom,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(
                l10n.usePresetLabel(widget.customization.accentColor.label),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _currentHex {
    final argb = widget.customization.effectiveAccentArgb;
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    final normalized = _normalizeUiHexColor(text);
    if (normalized == null) {
      setState(() => _error = AppLocalizations.of(context).hexDigitsErrorText);
      return;
    }
    await widget.repository.setCustomAccentColor(normalized);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _clearCustom() async {
    await widget.repository.setCustomAccentColor(null);
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
    backgroundColor: Theme.of(context).colorScheme.surface,
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          Text(
            l10n.chooseLanguageTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.chooseLanguageSubtitle,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Ink(
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
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
              style: TextStyle(color: scheme.onSurfaceVariant),
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

    return SpSettingsGroup(
      title: AppLocalizations.of(context).dashboardShortcutsTitle,
      rows: rows,
    );
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          SpIconBubble(
            icon: shortcut.icon,
            color: visible ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortcut.title(l10n),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  visible ? l10n.shortcutShownLabel : l10n.shortcutHiddenLabel,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('shortcut-up-${shortcut.id}'),
            tooltip: l10n.moveUpTooltip,
            onPressed: visible && canMoveUp ? onMoveUp : null,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
          IconButton(
            key: ValueKey('shortcut-down-${shortcut.id}'),
            tooltip: l10n.moveDownTooltip,
            onPressed: visible && canMoveDown ? onMoveDown : null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          Semantics(
            label: l10n.dashboardShortcutSemanticLabel(shortcut.title(l10n)),
            toggled: visible,
            child: Switch(
              key: ValueKey('shortcut-visible-${shortcut.id}'),
              value: visible,
              onChanged: onVisibleChanged,
              activeThumbColor: Theme.of(context).colorScheme.primary,
            ),
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SpSettingsRow(
      l10n.resetDashboardTitle,
      l10n.resetDashboardValue,
      trailing: Icon(Icons.restart_alt_rounded, color: scheme.onSurfaceVariant),
      onTap: onReset,
    );
  }
}
