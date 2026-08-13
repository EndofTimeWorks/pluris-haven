part of 'home_page.dart';

class SpNavigationEntry extends StatelessWidget {
  const SpNavigationEntry({super.key, required this.item, this.onTap});

  final HomeNavigationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          SpIconBubble(icon: item.icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: _spMuted, fontSize: 14),
                ),
              ],
            ),
          ),
          const Text(
            '>',
            style: TextStyle(
              color: _spMuted,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SpIconBubble extends StatelessWidget {
  const SpIconBubble({super.key, required this.icon, this.color = _spGold});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}

class SpPage extends StatelessWidget {
  const SpPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
      children: children,
    );
  }
}

class SpSearchField extends StatelessWidget {
  const SpSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      readOnly: onChanged == null,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: _spCard,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _spLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _spPurple),
        ),
      ),
    );
  }
}

class SpFilterRow extends StatelessWidget {
  const SpFilterRow({
    super.key,
    required this.filters,
    this.selected,
    this.onSelected,
  });

  final List<String> filters;
  final String? selected;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            FilterChip(
              label: Text(filters[index]),
              selected: selected == null
                  ? index == 0
                  : selected == filters[index],
              onSelected: onSelected == null
                  ? null
                  : (_) => onSelected!(filters[index]),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

bool _matchesQuery(String query, Iterable<String?> values) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return values.any(
    (value) => value != null && value.toLowerCase().contains(normalized),
  );
}

class SpSectionHeader extends StatelessWidget {
  const SpSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class SpEmptyState extends StatelessWidget {
  const SpEmptyState({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _spSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _spLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(color: _spMuted, height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class SpActionRow extends StatelessWidget {
  const SpActionRow({
    super.key,
    required this.primary,
    required this.secondary,
    this.onPrimary,
    this.onSecondary,
  });

  final String primary;
  final String secondary;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton(onPressed: onPrimary, child: Text(primary)),
        const SizedBox(width: 10),
        OutlinedButton(onPressed: onSecondary, child: Text(secondary)),
      ],
    );
  }
}

class SpSettingsGroup extends StatelessWidget {
  const SpSettingsGroup({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return SpCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Divider(height: 1, color: _spLine, indent: 16),
          ],
        ],
      ),
    );
  }
}

class SpSettingsRow extends StatelessWidget {
  const SpSettingsRow(
    this.title,
    this.subtitle, {
    super.key,
    this.trailing,
    this.onTap,
    this.interactive = true,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const AccentDot(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: _spMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          trailing ??
              const Text(
                '>',
                style: TextStyle(color: _spMuted, fontWeight: FontWeight.w800),
              ),
        ],
      ),
    );

    if (!interactive) {
      return content;
    }

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap:
            onTap ??
            () => showPlannedFeaturePopup(
              context,
              title: title,
              detail: subtitle,
            ),
        child: content,
      ),
    );
  }
}

Future<void> showPlannedFeaturePopup(
  BuildContext context, {
  required String title,
  required String detail,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(title),
      content: Text(AppLocalizations.of(context).plannedFeatureBody(detail)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).okButtonLabel),
        ),
      ],
    ),
  );
}

class SpSwitchRow extends StatelessWidget {
  const SpSwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        activeThumbColor: Theme.of(context).colorScheme.primary,
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _spMuted, fontSize: 13),
        ),
      ),
    );
  }
}

class AccentSwatch extends StatelessWidget {
  const AccentSwatch({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox(width: 22, height: 22),
    );
  }
}

class SpCard extends StatelessWidget {
  const SpCard({
    super.key,
    required this.child,
    this.onTap,
    this.outlined = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool outlined;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: _spCard,
        borderRadius: BorderRadius.circular(12),
        border: outlined ? Border.all(color: _spLine) : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class SpAvatar extends StatelessWidget {
  const SpAvatar({
    super.key,
    required this.size,
    required this.color,
    this.label,
    this.image,
    this.semanticLabel,
  });

  final double size;
  final Color color;
  final String? label;
  final ImageProvider? image;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel?.trim().isNotEmpty == true
          ? semanticLabel!.trim()
          : 'Decorative avatar placeholder',
      image: true,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          image: image == null
              ? null
              : DecorationImage(image: image!, fit: BoxFit.cover),
        ),
        alignment: Alignment.center,
        child: image != null || label == null
            ? null
            : ExcludeSemantics(
                child: Text(
                  label!,
                  style: TextStyle(
                    color: _spText,
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
      ),
    );
  }
}

class StoredAvatar extends StatelessWidget {
  const StoredAvatar({
    super.key,
    required this.size,
    required this.color,
    required this.label,
    this.avatarUrl,
    this.semanticLabel,
  });

  final double size;
  final Color color;
  final String label;
  final String? avatarUrl;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final source = avatarUrl?.trim();
    if (source == null || source.isEmpty) {
      return SpAvatar(
        size: size,
        color: color,
        label: label,
        semanticLabel: semanticLabel,
      );
    }
    if (source.startsWith('local-avatar:')) {
      return FutureBuilder<File?>(
        future: _localAvatarFile(source),
        builder: (context, snapshot) => SpAvatar(
          size: size,
          color: color,
          label: label,
          image: snapshot.data == null ? null : FileImage(snapshot.data!),
          semanticLabel: semanticLabel,
        ),
      );
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return SpAvatar(
        size: size,
        color: color,
        label: label,
        image: NetworkImage(source),
        semanticLabel: semanticLabel,
      );
    }
    return SpAvatar(
      size: size,
      color: color,
      label: label,
      semanticLabel: semanticLabel,
    );
  }
}

class AccentDot extends StatelessWidget {
  const AccentDot({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: _spGold, shape: BoxShape.circle),
      child: SizedBox(width: 20, height: 20),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).statusSemanticLabel(text),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _spSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: ExcludeSemantics(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _spMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeNavigationItem {
  const HomeNavigationItem(this.title, this.subtitle, this.section, this.icon);

  final String title;
  final String subtitle;
  final SpSection section;
  final IconData icon;
}
