part of 'home_page.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({
    super.key,
    required this.snapshot,
    required this.repository,
    required this.onImport,
  });

  final HomeSnapshot? snapshot;
  final HavenRepository repository;
  final VoidCallback onImport;

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _searchController = TextEditingController();
  late Stream<List<MemberSummary>> _currentFrontStream;
  String _query = '';
  String _filter = 'all';
  bool _sortByName = false;

  @override
  void initState() {
    super.initState();
    _currentFrontStream = widget.repository.watchCurrentFrontMembers();
  }

  @override
  void didUpdateWidget(covariant MembersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _currentFrontStream = widget.repository.watchCurrentFrontMembers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = <String, String>{
      'all': l10n.allFilter,
      'fronting': l10n.frontingFilter,
      'archived': l10n.archivedFilter,
      'deleted': l10n.deletedFilter,
    };
    return StreamBuilder<List<MemberSummary>>(
      stream: _filter == 'deleted'
          ? widget.repository.watchDeletedMembers(listOnly: true)
          : widget.repository.watchMembers(
              includeArchived: true,
              listOnly: true,
            ),
      builder: (context, membersSnapshot) {
        if (membersSnapshot.hasError && !membersSnapshot.hasData) {
          return SpPage(
            children: [
              SpDataLoadState(
                error: membersSnapshot.error,
                onRetry: () => setState(() {}),
              ),
            ],
          );
        }
        if (!membersSnapshot.hasData) {
          return const SpPage(children: [SpDataLoadState()]);
        }
        Widget showMembers(Set<String> activeMemberIds) {
          final members = _filteredMembers(
            membersSnapshot.data!,
            activeMemberIds,
          );
          final visualTheme = _visualThemeOf(context);
          final profileLayout =
              visualTheme == HavenVisualTheme.simplyPlural ||
              visualTheme == HavenVisualTheme.ampersand;
          if (profileLayout) {
            return _buildProfileLayout(
              context,
              l10n,
              filters,
              members,
              deleted: _filter == 'deleted',
            );
          }

          return SpPage(
            children: [
              SpSearchField(
                hintText: l10n.searchMembersHint,
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              SpFilterRow(
                filters: filters.values.toList(growable: false),
                selected: filters[_filter]!,
                onSelected: (label) => setState(
                  () => _filter = filters.entries
                      .firstWhere((entry) => entry.value == label)
                      .key,
                ),
              ),
              _sortControl(l10n),
              const SizedBox(height: 12),
              SpCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SpSectionHeader(
                      title: l10n.navigationMembers,
                      trailing: StatusPill(
                        text: '${widget.snapshot?.memberCount ?? 0}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (members.isEmpty)
                      SpEmptyState(
                        title: _query.trim().isEmpty && _filter == 'all'
                            ? l10n.noMembersSavedLocally
                            : l10n.noMatchingMembers,
                        body: _query.trim().isEmpty && _filter == 'all'
                            ? l10n.membersEmptyBody
                            : l10n.tryAnotherSearchOrFilter,
                      )
                    else
                      for (final member in members) ...[
                        _memberTile(member, deleted: _filter == 'deleted'),
                        if (member != members.last) const Divider(height: 1),
                      ],
                    const SizedBox(height: 14),
                    SpActionRow(
                      primary: l10n.addMemberButton,
                      secondary: l10n.importTitle,
                      onPrimary: () =>
                          showAddMemberSheet(context, widget.repository),
                      onSecondary: widget.onImport,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (_filter == 'fronting') {
          return StreamBuilder<List<MemberSummary>>(
            stream: _currentFrontStream,
            builder: (context, activeSnapshot) {
              if (activeSnapshot.hasError && !activeSnapshot.hasData) {
                return SpPage(
                  children: [
                    SpDataLoadState(
                      error: activeSnapshot.error,
                      onRetry: () => setState(() {}),
                    ),
                  ],
                );
              }
              if (!activeSnapshot.hasData) {
                return const SpPage(children: [SpDataLoadState()]);
              }
              return showMembers(
                activeSnapshot.data!.map((member) => member.id).toSet(),
              );
            },
          );
        }
        return showMembers(const {});
      },
    );
  }

  Widget _buildProfileLayout(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, String> filters,
    List<MemberSummary> members, {
    required bool deleted,
  }) {
    final visualTheme = _visualThemeOf(context);
    final padding = visualTheme == HavenVisualTheme.simplyPlural
        ? const EdgeInsets.fromLTRB(8, 10, 8, 20)
        : const EdgeInsets.fromLTRB(14, 12, 14, 24);
    final empty = members.isEmpty;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding.copyWith(bottom: 8),
          sliver: SliverList.list(
            children: [
              SpSearchField(
                hintText: l10n.searchMembersHint,
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              SpFilterRow(
                filters: filters.values.toList(growable: false),
                selected: filters[_filter]!,
                onSelected: (label) => setState(
                  () => _filter = filters.entries
                      .firstWhere((entry) => entry.value == label)
                      .key,
                ),
              ),
              _sortControl(l10n),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.navigationMembers,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusPill(text: '${widget.snapshot?.memberCount ?? 0}'),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    tooltip: l10n.addMemberButton,
                    onPressed: () =>
                        showAddMemberSheet(context, widget.repository),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                  ),
                ],
              ),
              if (empty) ...[
                const SizedBox(height: 8),
                SpEmptyState(
                  title: _query.trim().isEmpty && _filter == 'all'
                      ? l10n.noMembersSavedLocally
                      : l10n.noMatchingMembers,
                  body: _query.trim().isEmpty && _filter == 'all'
                      ? l10n.membersEmptyBody
                      : l10n.tryAnotherSearchOrFilter,
                ),
              ],
            ],
          ),
        ),
        if (!empty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: padding.left),
            sliver: SliverList.builder(
              itemCount: members.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SpCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: _memberTile(members[index], deleted: deleted),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: padding.copyWith(top: 6),
          sliver: SliverToBoxAdapter(
            child: OutlinedButton.icon(
              onPressed: widget.onImport,
              icon: const Icon(Icons.file_download_outlined),
              label: Text(l10n.importTitle),
            ),
          ),
        ),
      ],
    );
  }

  Widget _memberTile(MemberSummary member, {required bool deleted}) {
    if (deleted) {
      return DeletedMemberListTile(
        member: member,
        repository: widget.repository,
      );
    }
    return MemberListTile(member: member, repository: widget.repository);
  }

  Widget _sortControl(AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<bool>(
        tooltip: l10n.sortMembers,
        initialValue: _sortByName,
        onSelected: (value) => setState(() => _sortByName = value),
        itemBuilder: (context) => [
          PopupMenuItem(value: false, child: Text(l10n.savedMemberOrder)),
          PopupMenuItem(value: true, child: Text(l10n.memberNameOrder)),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sort_rounded, size: 20),
              const SizedBox(width: 6),
              Text(_sortByName ? l10n.memberNameOrder : l10n.savedMemberOrder),
            ],
          ),
        ),
      ),
    );
  }

  List<MemberSummary> _filteredMembers(
    List<MemberSummary> members,
    Set<String> activeMemberIds,
  ) {
    final filtered = [
      for (final member in members)
        if (_matchesQuery(_query, [member.displayName, member.pronouns]) &&
            switch (_filter) {
              'archived' => member.archived,
              'fronting' => activeMemberIds.contains(member.id),
              _ => true,
            })
          member,
    ];
    if (_sortByName) {
      filtered.sort((a, b) {
        final byName = a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });
    }
    return filtered;
  }
}

class DeletedMemberListTile extends StatelessWidget {
  const DeletedMemberListTile({
    super.key,
    required this.member,
    required this.repository,
  });

  final MemberSummary member;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: MemberAvatar(
          member: member,
          color: _colorFromHex(member.colorHex, fallback: scheme.primary),
          label: _memberAvatarLabel(member),
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          l10n.deletedStatus,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: l10n.memberActionsFor(
            member.displayName,
            member.id.substring(
              member.id.length > 8 ? member.id.length - 8 : 0,
            ),
          ),
          onSelected: (value) async {
            if (value == 'restore') {
              await repository.restoreDeletedMember(member.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..removeCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        member.archived
                            ? l10n.memberRestoredToArchive(member.displayName)
                            : l10n.memberRestored(member.displayName),
                      ),
                    ),
                  );
              }
            } else if (value == 'purge') {
              if (!context.mounted) return;
              confirmDelete(
                context,
                title: l10n.purgeMemberTitle,
                body: l10n.purgeMemberBody(member.displayName),
                onDelete: () => repository.purgeMember(member.id),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'restore', child: Text(l10n.restoreButton)),
            PopupMenuItem(value: 'purge', child: Text(l10n.purgeMemberButton)),
          ],
        ),
      ),
    );
  }
}

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.member,
    required this.repository,
  });

  final MemberSummary member;
  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: MemberAvatar(
          member: member,
          color: _memberColor(member, scheme.primary),
          label: _memberAvatarLabel(member),
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          _subtitle(l10n),
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        onTap: () async {
          final fullMember = await _fullMember();
          if (!context.mounted) return;
          showMemberProfileSheet(context, repository, fullMember);
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!member.archived)
              _FrontActionButton(
                actionKey: 'member-${member.id}',
                targetName: member.displayName,
                targetId: member.id,
                onPressed: (action) async {
                  final reminders = action == HavenFrontAction.add
                      ? await repository.addFrontMembers([member.id])
                      : await repository.setFrontMembers([member.id]);
                  if (context.mounted) {
                    await deliverAfterFrontReminders(
                      context,
                      repository,
                      reminders,
                    );
                    if (context.mounted) {
                      await _syncFrontNotification(context, repository);
                    }
                  }
                },
              ),
            PopupMenuButton<String>(
              tooltip: l10n.memberActionsFor(
                member.displayName,
                member.id.substring(
                  member.id.length > 8 ? member.id.length - 8 : 0,
                ),
              ),
              onSelected: (value) async {
                if (value == 'front') {
                  if (!await _confirmReplaceCurrentFront(context)) return;
                  final reminders = await repository.setFrontMembers([
                    member.id,
                  ]);
                  if (context.mounted) {
                    await deliverAfterFrontReminders(
                      context,
                      repository,
                      reminders,
                    );
                    if (context.mounted) {
                      await _syncFrontNotification(context, repository);
                    }
                  }
                } else if (value == 'edit') {
                  final fullMember = await _fullMember();
                  if (!context.mounted) return;
                  showMemberSheet(context, repository, member: fullMember);
                } else if (value == 'duplicate') {
                  final fullMember = await _fullMember();
                  if (!context.mounted) return;
                  showMemberSheet(
                    context,
                    repository,
                    initialDraft: _duplicateMemberDraft(fullMember, l10n),
                  );
                } else if (value == 'archive') {
                  await repository.archiveMember(member.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.memberArchived(member.displayName),
                          ),
                        ),
                      );
                  }
                } else if (value == 'restore') {
                  await repository.restoreMember(member.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.memberRestored(member.displayName),
                          ),
                        ),
                      );
                  }
                } else if (value == 'delete') {
                  if (!context.mounted) return;
                  confirmDelete(
                    context,
                    title: l10n.deleteMemberTitle,
                    body: l10n.deleteMemberBody(member.displayName),
                    onDelete: () => repository.deleteMember(member.id),
                    confirmLabel: l10n.removeMemberButton,
                    failureMessage: (error) =>
                        l10n.removeMemberFailed(error.toString()),
                  );
                }
              },
              itemBuilder: (context) => [
                if (!member.archived)
                  PopupMenuItem(
                    value: 'front',
                    child: Text(l10n.setFrontButton),
                  ),
                PopupMenuItem(value: 'edit', child: Text(l10n.editButton)),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text(l10n.duplicateButton),
                ),
                if (member.archived)
                  PopupMenuItem(
                    value: 'restore',
                    child: Text(l10n.restoreButton),
                  )
                else
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(l10n.archiveButton),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.removeMemberButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n) {
    final pronouns = member.pronouns?.isNotEmpty == true
        ? member.pronouns!
        : l10n.noPronounsLabel;
    final privacy = member.privacy?.trim();
    final parts = [
      pronouns,
      if (privacy != null && privacy.isNotEmpty) privacy,
      if (member.archived) l10n.archivedStatus,
    ];
    return parts.join(' - ');
  }

  Color _memberColor(MemberSummary member, Color fallback) {
    return _colorFromHex(member.colorHex, fallback: fallback);
  }

  Future<MemberSummary> _fullMember() async {
    final members = await repository.watchMembers(includeArchived: true).first;
    return members.firstWhere((candidate) => candidate.id == member.id);
  }
}

class _FrontActionButton extends StatelessWidget {
  const _FrontActionButton({
    required this.actionKey,
    required this.targetName,
    required this.targetId,
    required this.onPressed,
  });

  final String actionKey;
  final String targetName;
  final String targetId;
  final Future<void> Function(HavenFrontAction action) onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: ValueKey('front-action-button-$actionKey'),
          tooltip: l10n.frontActionFor(
            l10n.addToFrontButton,
            targetName,
            _shortFrontId(targetId),
          ),
          onPressed: () => onPressed(HavenFrontAction.add),
          icon: const Icon(Icons.add_rounded),
        ),
        IconButton(
          key: ValueKey('front-action-replace-$actionKey'),
          tooltip: l10n.frontActionFor(
            l10n.replaceCurrentFrontButton,
            targetName,
            _shortFrontId(targetId),
          ),
          onPressed: () async {
            if (await _confirmReplaceCurrentFront(context)) {
              await onPressed(HavenFrontAction.replace);
            }
          },
          icon: const Icon(Icons.swap_horiz_rounded),
        ),
      ],
    );
  }
}

Future<bool> _confirmReplaceCurrentFront(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.replaceCurrentFrontButton),
          content: Text(l10n.replaceCurrentFrontWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.replaceCurrentFrontButton),
            ),
          ],
        ),
      ) ??
      false;
}

void showMemberProfileSheet(
  BuildContext context,
  HavenRepository repository,
  MemberSummary member,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) => MemberProfileSheet(
      hostContext: context,
      repository: repository,
      member: member,
    ),
  );
}

class MemberProfileSheet extends StatelessWidget {
  const MemberProfileSheet({
    super.key,
    required this.hostContext,
    required this.repository,
    required this.member,
  });

  final BuildContext hostContext;
  final HavenRepository repository;
  final MemberSummary member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = _colorFromHex(member.colorHex, fallback: scheme.primary);
    final description = member.description?.trim();
    final pluralKitId = member.pluralKitId?.trim();

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MemberAvatar(
                  member: member,
                  color: color,
                  label: _memberAvatarLabel(member),
                  size: 72,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _memberPronouns(member, l10n),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusPill(
                            text: member.archived
                                ? l10n.archivedStatus
                                : l10n.activeStatus,
                          ),
                          if (member.colorHex?.trim().isNotEmpty == true)
                            StatusPill(text: member.colorHex!.toUpperCase()),
                          if (member.emoji?.trim().isNotEmpty == true)
                            StatusPill(text: member.emoji!.trim()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (description != null && description.isNotEmpty)
              SpCard(
                child: Text(description, style: const TextStyle(height: 1.4)),
              )
            else
              SpCard(
                child: Text(
                  l10n.noDescriptionYet,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 12),
            StreamBuilder<List<GroupSummary>>(
              stream: repository.watchGroups(),
              initialData: const [],
              builder: (context, groupsSnapshot) {
                return SpSettingsGroup(
                  title: l10n.profileTitle,
                  rows: [
                    SpSettingsRow(
                      l10n.pronounsFieldLabel,
                      _memberPronouns(member, l10n),
                      interactive: false,
                    ),
                    SpSettingsRow(
                      l10n.birthdayFieldLabel,
                      _emptyLabel(member.birthday, l10n),
                      interactive: false,
                    ),
                    SpSettingsRow(
                      l10n.emojiFieldLabel,
                      _emptyLabel(member.emoji, l10n),
                      interactive: false,
                    ),
                    SpSettingsRow(
                      l10n.privacyFieldLabel,
                      _emptyLabel(member.privacy, l10n),
                      interactive: false,
                    ),
                    SpSettingsRow(
                      l10n.pluralKitIdFieldLabel,
                      pluralKitId == null || pluralKitId.isEmpty
                          ? l10n.notLinkedLabel
                          : pluralKitId,
                      interactive: false,
                    ),
                    SpSettingsRow(
                      l10n.navigationGroups,
                      _memberGroupLabel(
                        member,
                        groupsSnapshot.data ?? const <GroupSummary>[],
                        l10n,
                      ),
                      interactive: false,
                    ),
                    SpSettingsRow(
                      l10n.avatarFieldLabel,
                      member.avatarUrl?.trim().isNotEmpty == true
                          ? member.avatarUrl!
                          : l10n.defaultLabel,
                      interactive: false,
                    ),
                  ],
                );
              },
            ),
            MemberTagsSection(repository: repository, memberId: member.id),
            MemberCustomFieldsSection(
              repository: repository,
              memberId: member.id,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_hasLocalAvatar(member)) ...[
                  OutlinedButton.icon(
                    onPressed: () => _saveAvatarCopy(context),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(l10n.saveAvatarCopyButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _shareAvatar(context),
                    icon: const Icon(Icons.ios_share_outlined),
                    label: Text(l10n.shareAvatarTemporarilyButton),
                  ),
                ],
                if (!member.archived)
                  FilledButton.icon(
                    onPressed: () async {
                      if (!await _confirmReplaceCurrentFront(context)) return;
                      final reminders = await repository.setFrontMembers([
                        member.id,
                      ]);
                      if (context.mounted) {
                        await deliverAfterFrontReminders(
                          context,
                          repository,
                          reminders,
                        );
                        if (context.mounted) {
                          await _syncFrontNotification(context, repository);
                        }
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.radio_button_checked_rounded),
                    label: Text(l10n.setFrontButton),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showMemberSheet(context, repository, member: member);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.editButton),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!hostContext.mounted) {
                        return;
                      }
                      showMemberSheet(
                        hostContext,
                        repository,
                        initialDraft: _duplicateMemberDraft(member, l10n),
                      );
                    });
                  },
                  icon: const Icon(Icons.content_copy_rounded),
                  label: Text(l10n.duplicateButton),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (member.archived) {
                      await repository.restoreMember(member.id);
                    } else {
                      await repository.archiveMember(member.id);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    if (hostContext.mounted) {
                      ScaffoldMessenger.of(hostContext)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              member.archived
                                  ? l10n.memberRestored(member.displayName)
                                  : l10n.memberArchived(member.displayName),
                            ),
                          ),
                        );
                    }
                  },
                  icon: Icon(
                    member.archived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                  label: Text(
                    member.archived ? l10n.restoreButton : l10n.archiveButton,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _hasLocalAvatar(MemberSummary member) =>
      member.avatarUrl?.trim().startsWith(localAvatarReferencePrefix) == true;

  Future<void> _saveAvatarCopy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bytes = await _avatarBytes();
    if (!context.mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.avatarExportUnavailable)));
      return;
    }
    final saved = await NativeFileDialog.saveBytes(
      dialogTitle: l10n.saveAvatarCopyButton,
      fileName: _avatarExportFileName(member),
      bytes: bytes,
      mimeType: _avatarMimeType(member.avatarUrl),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? l10n.avatarCopySaved : l10n.saveCancelled),
      ),
    );
  }

  Future<void> _shareAvatar(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bytes = await _avatarBytes();
    if (!context.mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.avatarExportUnavailable)));
      return;
    }
    await NativeFileDialog.shareBytes(
      fileName: _avatarExportFileName(member),
      bytes: bytes,
      mimeType: _avatarMimeType(member.avatarUrl),
    );
  }

  Future<Uint8List?> _avatarBytes() {
    final reference = member.avatarUrl?.trim();
    if (reference == null || reference.isEmpty) return Future.value();
    return repository.readAvatar(reference);
  }
}

String _avatarExportFileName(MemberSummary member) {
  final name = member.displayName
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final safeName = name.isEmpty
      ? 'avatar'
      : name.length > 96
      ? name.substring(0, 96)
      : name;
  return '$safeName${_avatarExtension(member.avatarUrl)}';
}

String _avatarExtension(String? reference) {
  final name = reference?.split('/').last.toLowerCase() ?? '';
  for (final extension in <String>['.png', '.jpg', '.jpeg', '.webp', '.gif']) {
    if (name.endsWith(extension)) return extension;
  }
  return '.png';
}

String _avatarMimeType(String? reference) =>
    switch (_avatarExtension(reference)) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/png',
    };

class MemberTagsSection extends StatelessWidget {
  const MemberTagsSection({
    super.key,
    required this.repository,
    required this.memberId,
  });

  final HavenRepository repository;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<Tag>>(
      stream: repository.watchTagsForMember(memberId),
      initialData: const [],
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <Tag>[];
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SpSettingsGroup(
            title: l10n.tagsTitle,
            rows: [
              SpSettingsRow(
                l10n.memberTagsTitle,
                _tagSummary(tags, l10n),
                trailing: Icon(
                  Icons.sell_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => showMemberTagsSheet(
                  context,
                  repository: repository,
                  memberId: memberId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _tagSummary(List<Tag> tags, AppLocalizations l10n) {
  if (tags.isEmpty) {
    return l10n.noneLabel;
  }
  return tags.map((tag) => tag.name).join(', ');
}

void showMemberTagsSheet(
  BuildContext context, {
  required HavenRepository repository,
  required String memberId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) =>
        MemberTagsSheet(repository: repository, memberId: memberId),
  );
}

class MemberTagsSheet extends StatefulWidget {
  const MemberTagsSheet({
    super.key,
    required this.repository,
    required this.memberId,
  });

  final HavenRepository repository;
  final String memberId;

  @override
  State<MemberTagsSheet> createState() => _MemberTagsSheetState();
}

class _MemberTagsSheetState extends State<MemberTagsSheet> {
  final _nameController = TextEditingController();
  final _colorController = TextEditingController(text: '#F2C75C');
  final Set<String> _selectedTagIds = {};
  final Set<String> _initialTagIds = {};
  late final Stream<List<Tag>> _tagsStream;
  late final Stream<List<Tag>> _memberTagsStream;
  bool _seeded = false;
  String? _error;

  bool get _isDirty =>
      _nameController.text.trim().isNotEmpty ||
      !_selectedTagIds.containsAll(_initialTagIds) ||
      !_initialTagIds.containsAll(_selectedTagIds);

  @override
  void initState() {
    super.initState();
    _tagsStream = widget.repository.watchTags();
    _memberTagsStream = widget.repository.watchTagsForMember(widget.memberId);
  }

  Future<void> _tryDismiss() async {
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }
    final choice = await _askAboutUnsavedChanges(context);
    if (!mounted) return;
    if (choice == _EditorDismissChoice.discard) Navigator.pop(context);
    if (choice == _EditorDismissChoice.save) await _save();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _tryDismiss();
    },
    child: _buildContents(context),
  );

  Widget _buildContents(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: StreamBuilder<List<Tag>>(
          stream: _tagsStream,
          initialData: const [],
          builder: (context, allTagsSnapshot) {
            final allTags = allTagsSnapshot.data ?? const <Tag>[];
            return StreamBuilder<List<Tag>>(
              stream: _memberTagsStream,
              builder: (context, memberTagsSnapshot) {
                if (!memberTagsSnapshot.hasData) {
                  return SpDataLoadState(error: memberTagsSnapshot.error);
                }
                final memberTags = memberTagsSnapshot.data ?? const <Tag>[];
                if (!_seeded) {
                  _selectedTagIds
                    ..clear()
                    ..addAll(memberTags.map((tag) => tag.id));
                  _initialTagIds
                    ..clear()
                    ..addAll(_selectedTagIds);
                  _seeded = true;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.memberTagsTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.memberTagsDescription,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (allTags.isEmpty)
                      Text(
                        l10n.noTagsYet,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in allTags)
                            FilterChip(
                              avatar: _TagDot(tag: tag),
                              label: Text(tag.name),
                              selected: _selectedTagIds.contains(tag.id),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _selectedTagIds.add(tag.id);
                                } else {
                                  _selectedTagIds.remove(tag.id);
                                }
                              }),
                              onDeleted: () => _deleteTag(tag),
                              deleteIcon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 18),
                    TextField(
                      key: const ValueKey('member-tag-name-field'),
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.newTagFieldLabel,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('member-tag-color-field'),
                      controller: _colorController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.tagColourFieldLabel,
                        hintText: '#F2C75C',
                        errorText: _error,
                        prefixIcon: Center(
                          widthFactor: 1,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _colorFromHex(
                                _normalizeUiHexColor(_colorController.text),
                                fallback: scheme.primary,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (_error != null) {
                          setState(() => _error = null);
                        } else {
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const ValueKey('create-member-tag-button'),
                          onPressed: _createTag,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l10n.createTagButton),
                        ),
                        FilledButton.icon(
                          key: const ValueKey('save-member-tags-button'),
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(l10n.saveTagsButton),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<bool> _createTag() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).nameTagFirstError);
      return false;
    }
    final colorHex = _normalizeUiHexColor(_colorController.text);
    if (colorHex == null) {
      setState(
        () => _error = AppLocalizations.of(context).invalidHexColorError,
      );
      return false;
    }
    final now = DateTime.now().toUtc();
    final tag = Tag(
      id: newLocalId('tag'),
      systemId: localSystemId,
      name: name,
      colorHex: colorHex,
      createdAt: now,
      updatedAt: now,
    );
    await widget.repository.saveTag(tag);
    if (!mounted) {
      return false;
    }
    setState(() {
      _selectedTagIds.add(tag.id);
      _nameController.clear();
      _error = null;
    });
    return true;
  }

  Future<void> _deleteTag(Tag tag) async {
    final l10n = AppLocalizations.of(context);
    await confirmDelete(
      context,
      title: l10n.deleteTagTitle(tag.name),
      body: l10n.deleteTagBody,
      onDelete: () async {
        await widget.repository.deleteTag(tag.id);
        if (mounted) setState(() => _selectedTagIds.remove(tag.id));
      },
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isNotEmpty && !await _createTag()) return;
    await widget.repository.setMemberTags(
      widget.memberId,
      _selectedTagIds.toList(growable: false),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _TagDot extends StatelessWidget {
  const _TagDot({required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _colorFromHex(
          tag.colorHex,
          fallback: Theme.of(context).colorScheme.primary,
        ),
        shape: BoxShape.circle,
      ),
      child: const SizedBox(width: 12, height: 12),
    );
  }
}

class MemberCustomFieldsSection extends StatelessWidget {
  const MemberCustomFieldsSection({
    super.key,
    required this.repository,
    required this.memberId,
  });

  final HavenRepository repository;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<CustomFieldSummary>>(
      stream: repository.watchCustomFields(),
      initialData: const [],
      builder: (context, fieldsSnapshot) {
        final fields = fieldsSnapshot.data ?? const <CustomFieldSummary>[];
        return StreamBuilder<List<CustomFieldValueSummary>>(
          stream: repository.watchCustomFieldValues(memberId: memberId),
          initialData: const [],
          builder: (context, valuesSnapshot) {
            final values =
                valuesSnapshot.data ?? const <CustomFieldValueSummary>[];
            final valuesByField = {
              for (final value in values) value.fieldId: value,
            };

            if (fields.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SpSettingsGroup(
                title: l10n.dataTitle,
                rows: [
                  for (final field in fields)
                    Builder(
                      builder: (context) {
                        final value = valuesByField[field.id];
                        return SpSettingsRow(
                          field.name,
                          value == null || value.displayValue.trim().isEmpty
                              ? l10n.notSetLabel
                              : value.displayValue,
                          subtitleWidget: CustomFieldValueDisplay(
                            field: field,
                            value: value,
                            emptyLabel: l10n.notSetLabel,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          trailing: _customFieldPrivacyPill(field),
                          onTap: () => showCustomFieldValueSheet(
                            context,
                            repository: repository,
                            field: field,
                            value: value,
                            memberId: memberId,
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _customFieldPrivacyPill(CustomFieldSummary? field) {
    final privacy = field?.privacy?.trim();
    if (privacy == null || privacy.isEmpty) {
      return const SizedBox.shrink();
    }
    return StatusPill(text: privacy);
  }
}

void showCustomFieldValueSheet(
  BuildContext context, {
  required HavenRepository repository,
  required CustomFieldSummary field,
  required CustomFieldValueSummary? value,
  required String? memberId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => CustomFieldValueSheet(
      repository: repository,
      field: field,
      value: value,
      memberId: memberId,
    ),
  );
}

class CustomFieldValueSheet extends StatefulWidget {
  const CustomFieldValueSheet({
    super.key,
    required this.repository,
    required this.field,
    required this.value,
    required this.memberId,
  });

  final HavenRepository repository;
  final CustomFieldSummary field;
  final CustomFieldValueSummary? value;
  final String? memberId;

  @override
  State<CustomFieldValueSheet> createState() => _CustomFieldValueSheetState();
}

class _CustomFieldValueSheetState extends State<CustomFieldValueSheet> {
  late final TextEditingController _valueController;
  late bool _booleanValue;
  String? _selectedChoice;
  late Set<String> _selectedChoices;
  String? _valueError;

  @override
  void initState() {
    super.initState();
    final value = widget.value?.value;
    _valueController = TextEditingController(
      text: value is Map || value is List
          ? const JsonEncoder.withIndent('  ').convert(value)
          : displayCustomFieldValue(value),
    );
    _booleanValue = value == true || value?.toString().toLowerCase() == 'true';
    _selectedChoice = value is String ? value : null;
    _selectedChoices = switch (value) {
      List values => values.map((item) => item.toString()).toSet(),
      String text when text.trim().isNotEmpty =>
        text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet(),
      _ => <String>{},
    };
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final privacy = widget.field.privacy?.trim();
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.field.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              [
                customFieldTypeLabel(l10n, widget.field.fieldType),
                if (privacy != null && privacy.isNotEmpty) privacy,
              ].join(' - '),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _buildValueEditor(context, l10n),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const ValueKey('save-custom-field-value-button'),
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.saveValueButton),
                ),
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.backspace_outlined),
                  label: Text(l10n.clearButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueEditor(BuildContext context, AppLocalizations l10n) {
    final type = widget.field.fieldType;
    final choices = customFieldChoices(widget.field);
    if (type == 'boolean') {
      return SwitchListTile.adaptive(
        key: const ValueKey('custom-field-value-field'),
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.valueFieldLabel),
        value: _booleanValue,
        onChanged: (value) => setState(() => _booleanValue = value),
      );
    }
    if (type == 'select' && choices.isNotEmpty) {
      final values = <String>{...choices, ?_selectedChoice}.toList();
      return DropdownButtonFormField<String>(
        key: const ValueKey('custom-field-value-field'),
        initialValue: _selectedChoice,
        decoration: InputDecoration(labelText: l10n.valueFieldLabel),
        items: [
          for (final choice in values)
            DropdownMenuItem(value: choice, child: Text(choice)),
        ],
        onChanged: (value) => setState(() => _selectedChoice = value),
      );
    }
    if (type == 'multiselect' && choices.isNotEmpty) {
      return InputDecorator(
        key: const ValueKey('custom-field-value-field'),
        decoration: InputDecoration(labelText: l10n.valueFieldLabel),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final choice in choices)
              FilterChip(
                label: Text(choice),
                selected: _selectedChoices.contains(choice),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedChoices.add(choice);
                    } else {
                      _selectedChoices.remove(choice);
                    }
                  });
                },
              ),
          ],
        ),
      );
    }

    final multiline =
        type == 'long_text' || type == 'markdown' || type == 'json';
    final noChoices =
        (type == 'select' || type == 'multiselect') && choices.isEmpty;
    return TextField(
      key: const ValueKey('custom-field-value-field'),
      controller: _valueController,
      autofocus: true,
      minLines: multiline ? 4 : 1,
      maxLines: multiline ? 10 : 1,
      keyboardType: switch (type) {
        'number' => const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        'url' => TextInputType.url,
        _ => multiline ? TextInputType.multiline : TextInputType.text,
      },
      textInputAction: multiline
          ? TextInputAction.newline
          : TextInputAction.done,
      readOnly: type == 'datetime',
      onTap: switch (type) {
        'datetime' => _pickDateTime,
        _ => null,
      },
      decoration: InputDecoration(
        labelText: l10n.valueFieldLabel,
        hintText: noChoices
            ? l10n.customFieldNoChoices
            : l10n.leaveBlankToClearHint,
        helperText: type == 'date' ? l10n.customFieldDateFormat : null,
        errorText: _valueError,
        suffixIcon: switch (type) {
          'date' => IconButton(
            tooltip: l10n.chooseDateButton,
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          'datetime' => const Icon(Icons.calendar_month_rounded),
          'url' => const Icon(Icons.link_rounded),
          'color' => const Icon(Icons.palette_outlined),
          'markdown' => const Icon(Icons.text_fields_rounded),
          'json' => const Icon(Icons.data_object_rounded),
          _ => null,
        },
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final text = _valueController.text.trim();
    Object? value;
    switch (widget.field.fieldType) {
      case 'boolean':
        value = _booleanValue;
      case 'select':
        value = customFieldChoices(widget.field).isEmpty
            ? text
            : _selectedChoice;
      case 'multiselect':
        value = customFieldChoices(widget.field).isEmpty
            ? text
            : _selectedChoices.toList(growable: false);
      case 'number':
        value = num.tryParse(text);
        if (text.isNotEmpty && value == null) {
          setState(() => _valueError = l10n.customFieldInvalidNumber);
          return;
        }
      case 'date':
        if (text.isNotEmpty && !_isValidDateOnly(text)) {
          setState(() => _valueError = l10n.customFieldInvalidDate);
          return;
        }
        value = text;
      case 'url':
        final uri = Uri.tryParse(text);
        if (text.isNotEmpty &&
            (uri == null ||
                (uri.scheme != 'https' && uri.scheme != 'http') ||
                uri.host.isEmpty)) {
          setState(() => _valueError = l10n.customFieldInvalidLink);
          return;
        }
        value = text;
      case 'color':
        if (text.isNotEmpty && _customFieldColor(text) == null) {
          setState(() => _valueError = l10n.invalidHexColorError);
          return;
        }
        value = text;
      case 'json':
        if (text.isEmpty) {
          value = null;
        } else {
          try {
            value = jsonDecode(text);
          } on FormatException {
            setState(() => _valueError = l10n.customFieldInvalidJson);
            return;
          }
        }
      default:
        value = text;
    }
    await widget.repository.setCustomFieldValue(
      fieldId: widget.field.id,
      memberId: widget.memberId,
      value: value,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _clear() async {
    await widget.repository.setCustomFieldValue(
      fieldId: widget.field.id,
      memberId: widget.memberId,
      value: null,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_valueController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _valueController.text = _dateOnlyText(picked);
      _valueError = null;
    });
  }

  Future<void> _pickDateTime() async {
    final initial = DateTime.tryParse(_valueController.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _valueController.text = selected.toIso8601String();
      _valueError = null;
    });
  }
}

String _dateOnlyText(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

bool _isValidDateOnly(String text) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (match == null) return false;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

String _memberPronouns(MemberSummary member, AppLocalizations l10n) {
  final pronouns = member.pronouns?.trim();
  return pronouns == null || pronouns.isEmpty ? l10n.noPronounsLabel : pronouns;
}

String _emptyLabel(String? value, AppLocalizations l10n) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? l10n.notSetLabel : trimmed;
}

String _memberGroupLabel(
  MemberSummary member,
  List<GroupSummary> groups,
  AppLocalizations l10n,
) {
  final namesById = {for (final group in groups) group.id: group.name};
  final ids = <String>{
    ...member.groupIds,
    if (member.groupIds.isEmpty && member.folderId != null) member.folderId!,
  };
  if (ids.isEmpty) {
    return l10n.noneLabel;
  }

  return [for (final id in ids) namesById[id] ?? id].join(', ');
}

MemberDraft _duplicateMemberDraft(MemberSummary member, AppLocalizations l10n) {
  return _memberDraft(
    member,
    displayName: l10n.duplicateMemberName(member.displayName),
  );
}

MemberDraft _memberDraft(MemberSummary member, {required String displayName}) {
  return MemberDraft(
    displayName: displayName,
    pronouns: member.pronouns,
    colorHex: member.colorHex,
    birthday: member.birthday,
    emoji: member.emoji,
    privacy: member.privacy,
    description: member.description,
    avatarUrl: member.avatarUrl,
    folderId: member.folderId,
    groupIds: member.groupIds,
  );
}

String _memberAvatarLabel(MemberSummary member) {
  final emoji = member.emoji?.trim();
  return emoji == null || emoji.isEmpty
      ? _initialFor(member.displayName)
      : emoji;
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    required this.color,
    required this.label,
    this.size = 42,
  });

  final MemberSummary member;
  final Color color;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avatarSemanticLabel = l10n.memberAvatarSemanticLabel(
      member.displayName,
    );
    final avatarUrl = member.avatarUrl;
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return SpAvatar(
        size: size,
        color: color,
        label: label,
        semanticLabel: avatarSemanticLabel,
      );
    }
    if (avatarUrl.startsWith('local-avatar:')) {
      return FutureBuilder<Uint8List?>(
        future: _localAvatarFile(avatarUrl),
        builder: (context, snapshot) {
          final file = snapshot.data;
          return SpAvatar(
            size: size,
            color: color,
            label: label,
            image: file == null ? null : MemoryImage(file),
            semanticLabel: avatarSemanticLabel,
          );
        },
      );
    }
    return SpAvatar(
      size: size,
      color: color,
      label: label,
      semanticLabel: avatarSemanticLabel,
    );
  }
}

Future<Uint8List?> _localAvatarFile(String avatarUrl) =>
    _localAvatarStore.read(avatarUrl);

String _initialFor(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
}

Color _colorFromHex(String? colorHex, {required Color fallback}) {
  final value = colorHex?.replaceFirst('#', '');
  if (value == null || value.length != 6) {
    return fallback;
  }

  final parsed = int.tryParse('FF$value', radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

void showAddMemberSheet(BuildContext context, HavenRepository repository) {
  showMemberSheet(context, repository);
}

void showMemberSheet(
  BuildContext context,
  HavenRepository repository, {
  MemberSummary? member,
  MemberDraft? initialDraft,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    enableDrag: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => AddMemberSheet(
      repository: repository,
      member: member,
      initialDraft: initialDraft,
    ),
  );
}

class AddMemberSheet extends StatefulWidget {
  const AddMemberSheet({
    super.key,
    required this.repository,
    this.member,
    this.initialDraft,
  });

  final HavenRepository repository;
  final MemberSummary? member;
  final MemberDraft? initialDraft;

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final _nameController = TextEditingController();
  final _pronounsController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emojiController = TextEditingController();
  final _privacyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _avatarController = TextEditingController();
  final _pluralKitController = TextEditingController();
  final _colorController = TextEditingController(
    text: _hexFromAccent(HavenAccentColor.purple),
  );
  String? _folderId;
  final Set<String> _groupIds = {};
  String? _colorError;
  String? _nameError;
  String? _avatarMessage;
  bool _isSaving = false;
  late String _initialSignature;

  bool get _isEditing => widget.member != null;
  bool get _isDirty => _signature() != _initialSignature;

  String _signature() => jsonEncode([
    _nameController.text,
    _pronounsController.text,
    _birthdayController.text,
    _emojiController.text,
    _privacyController.text,
    _descriptionController.text,
    _avatarController.text,
    _pluralKitController.text,
    _colorController.text,
    _folderId,
    _groupIds.toList()..sort(),
  ]);

  Future<void> _tryDismiss() async {
    if (_isSaving) return;
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }
    final choice = await _askAboutUnsavedChanges(context);
    if (!mounted) return;
    if (choice == _EditorDismissChoice.discard) Navigator.pop(context);
    if (choice == _EditorDismissChoice.save) await _save();
  }

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    if (member == null) {
      final draft = widget.initialDraft;
      if (draft != null) {
        _seedFromDraft(draft);
      }
      _attachAvatarPreviewListeners();
      _initialSignature = _signature();
      return;
    }

    _seedFromMember(member);
    _attachAvatarPreviewListeners();
    _initialSignature = _signature();
  }

  void _seedFromMember(MemberSummary member) {
    _seedFromDraft(_memberDraft(member, displayName: member.displayName));
    _pluralKitController.text = member.pluralKitId ?? '';
  }

  void _seedFromDraft(MemberDraft draft) {
    _nameController.text = draft.displayName;
    _pronounsController.text = draft.pronouns ?? '';
    _birthdayController.text = draft.birthday ?? '';
    _emojiController.text = draft.emoji ?? '';
    _privacyController.text = draft.privacy ?? '';
    _descriptionController.text = draft.description ?? '';
    _avatarController.text = draft.avatarUrl ?? '';
    _pluralKitController.text = draft.pluralKitId ?? '';
    _folderId = draft.folderId;
    _groupIds
      ..clear()
      ..addAll(draft.groupIds ?? const <String>[]);
    if (_folderId != null) {
      _groupIds.add(_folderId!);
    }
    _colorController.text =
        _normalizeUiHexColor(draft.colorHex ?? '') ??
        _hexFromAccent(HavenAccentColor.purple);
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _emojiController,
      _avatarController,
      _colorController,
    ]) {
      controller.removeListener(_refreshAvatarPreview);
    }
    _nameController.dispose();
    _pronounsController.dispose();
    _birthdayController.dispose();
    _emojiController.dispose();
    _privacyController.dispose();
    _descriptionController.dispose();
    _avatarController.dispose();
    _pluralKitController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _refreshAvatarPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  void _attachAvatarPreviewListeners() {
    for (final controller in [
      _nameController,
      _emojiController,
      _avatarController,
      _colorController,
    ]) {
      controller.addListener(_refreshAvatarPreview);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _tryDismiss();
    },
    child: _buildContents(context),
  );

  Widget _buildContents(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final previewName = _nameController.text.trim().isEmpty
        ? l10n.memberPreviewName
        : _nameController.text;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.alterProfileTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('member-name-field'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.nameFieldLabel,
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-pronouns-field'),
              controller: _pronounsController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.pronounsFieldLabel),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-birthday-field'),
              controller: _birthdayController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.birthdayFieldLabel,
                hintText: l10n.birthdayFieldHint,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-emoji-field'),
              controller: _emojiController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.emojiFieldLabel),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-privacy-field'),
              controller: _privacyController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.privacyFieldLabel,
                hintText: l10n.privacyFieldHint,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.descriptionFieldLabel,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-avatar-field'),
              controller: _avatarController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.avatarReferenceFieldLabel,
                hintText: 'https://... or local-avatar:...',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                MemberAvatar(
                  member: MemberSummary(
                    id: 'member-editor-preview',
                    displayName: previewName,
                    colorHex: _normalizeUiHexColor(_colorController.text),
                    emoji: _emojiController.text,
                    avatarUrl: _nullIfBlank(_avatarController.text),
                  ),
                  color: _colorFromHex(
                    _normalizeUiHexColor(_colorController.text),
                    fallback: scheme.primary,
                  ),
                  label: _emojiController.text.trim().isEmpty
                      ? _initialFor(previewName)
                      : _emojiController.text.trim(),
                  size: 52,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('pick-member-avatar-button'),
                        onPressed: _chooseAvatar,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(l10n.chooseImageButton),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('clear-member-avatar-button'),
                        onPressed: _clearAvatar,
                        icon: const Icon(Icons.close_rounded),
                        label: Text(l10n.clearButton),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_avatarMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _avatarMessage!,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-pluralkit-field'),
              controller: _pluralKitController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.pluralKitIdFieldLabel,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<GroupSummary>>(
              stream: widget.repository.watchGroups(),
              initialData: const [],
              builder: (context, snapshot) {
                final groups = snapshot.data ?? const <GroupSummary>[];
                final groupIds = groups.map((group) => group.id).toSet();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KeyedSubtree(
                      key: ValueKey(
                        'primary-group-${groups.map((group) => group.id).join(',')}-$_folderId',
                      ),
                      child: DropdownButtonFormField<String?>(
                        key: const ValueKey('member-primary-group-field'),
                        initialValue: _folderId,
                        decoration: InputDecoration(
                          labelText: l10n.primaryGroupFieldLabel,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.noPrimaryGroupOption),
                          ),
                          if (_folderId != null &&
                              !groupIds.contains(_folderId))
                            DropdownMenuItem<String?>(
                              value: _folderId,
                              child: Text(l10n.unknownGroupLabel),
                            ),
                          for (final group in groups)
                            DropdownMenuItem<String?>(
                              value: group.id,
                              child: Text(group.name),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          _folderId = value;
                          if (_folderId != null) _groupIds.add(_folderId!);
                        }),
                      ),
                    ),
                    if (groups.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        l10n.memberGroupsTitle,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final group in groups)
                            FilterChip(
                              label: Text(group.name),
                              selected: _groupIds.contains(group.id),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _groupIds.add(group.id);
                                  _folderId ??= group.id;
                                } else {
                                  _groupIds.remove(group.id);
                                  if (_folderId == group.id) {
                                    _folderId = _groupIds.isEmpty
                                        ? null
                                        : _groupIds.first;
                                  }
                                }
                              }),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final color in HavenAccentColor.values)
                  ChoiceChip(
                    label: Text(color.label),
                    selected:
                        _normalizeUiHexColor(_colorController.text) ==
                        _hexFromAccent(color),
                    onSelected: (_) => setState(() {
                      _colorController.text = _hexFromAccent(color);
                      _colorError = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('member-color-hex-field'),
              controller: _colorController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.colorHexFieldLabel,
                hintText: '#7B61FF',
                errorText: _colorError,
              ),
              onChanged: (_) {
                if (_colorError != null) {
                  setState(() => _colorError = null);
                }
              },
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('save-member-button'),
              onPressed: _isSaving ? null : _save,
              child: Text(
                _isEditing ? l10n.saveAlterButton : l10n.createAlterButton,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_nameController.text.trim().isEmpty) {
      setState(
        () => _nameError = AppLocalizations.of(context).nameRequiredError,
      );
      return;
    }
    final colorHex = _normalizeUiHexColor(_colorController.text);
    if (colorHex == null) {
      setState(
        () => _colorError = AppLocalizations.of(context).hexDigitsErrorText,
      );
      return;
    }

    final draft = MemberDraft(
      displayName: _nameController.text.trim(),
      pronouns: _pronounsController.text,
      colorHex: colorHex,
      birthday: _birthdayController.text,
      emoji: _emojiController.text,
      privacy: _privacyController.text,
      description: _descriptionController.text,
      avatarUrl: _avatarController.text,
      pluralKitId: _pluralKitController.text,
      folderId: _folderId,
      groupIds: _groupIds.toList(growable: false),
    );
    setState(() => _isSaving = true);
    try {
      final member = widget.member;
      if (member == null) {
        await widget.repository.saveMember(draft);
      } else {
        await widget.repository.updateMember(member.id, draft);
      }
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).couldNotSaveDraft),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _chooseAvatar() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _avatarMessage = l10n.openingImagePickerStatus);
    try {
      final result = await NativeFileDialog.pickFiles(
        type: NativeFileType.image,
        allowMultiple: false,
        dialogTitle: l10n.chooseMemberAvatarTitle,
        maximumBytes: maximumAvatarBytes,
      );
      final files = result?.files ?? const <NativePlatformFile>[];
      final file = files.isEmpty ? null : files.first;
      if (file == null) {
        if (mounted) {
          setState(() => _avatarMessage = l10n.noImageSelectedStatus);
        }
        return;
      }
      final bytes = await _readManualAvatarFile(file);
      final ref = await _storeManualAvatar(file.name, bytes);
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarController.text = ref;
        _avatarMessage = l10n.avatarSavedStatus;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _avatarMessage =
              _manualAvatarValidationMessage(l10n, error) ??
              l10n.couldNotSaveAvatar(error),
        );
      }
    }
  }

  void _clearAvatar() {
    setState(() {
      _avatarController.clear();
      _avatarMessage = AppLocalizations.of(context).avatarClearedStatus;
    });
  }
}

String _hexFromAccent(HavenAccentColor color) =>
    '#${color.argb.toRadixString(16).substring(2).toUpperCase()}';

Future<Uint8List> _readManualAvatarFile(NativePlatformFile file) async {
  if (file.size <= 0) {
    await file.dispose();
    throw const AvatarFileException(AvatarFileIssue.empty);
  }
  if (file.size > maximumAvatarBytes) {
    await file.dispose();
    throw const AvatarFileException(AvatarFileIssue.tooLarge);
  }
  final bytes = await file.readBytes();
  validateRasterAvatarBytes(bytes);
  return bytes;
}

String? _manualAvatarValidationMessage(AppLocalizations l10n, Object error) {
  if (error is NativePickedFileTooLargeException) {
    return l10n.selectedImageTooLargeError;
  }
  if (error is! AvatarFileException) return null;
  return switch (error.issue) {
    AvatarFileIssue.empty => l10n.selectedImageEmptyError,
    AvatarFileIssue.tooLarge => l10n.selectedImageTooLargeError,
    AvatarFileIssue.unsupportedType => l10n.selectedImageUnsupportedTypeError,
  };
}

Future<String> _storeManualAvatar(String sourceName, Uint8List bytes) async {
  final mimeType = validateRasterAvatarBytes(bytes);
  final extension = switch (mimeType) {
    'image/jpeg' => 'jpg',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'png',
  };
  final stem = _manualAvatarStem(sourceName);
  final fileName = '${newLocalId('manual')}_$stem.$extension';
  await LocalAvatarStore().write(fileName, bytes);
  return 'local-avatar:$fileName';
}

String _manualAvatarStem(String sourceName) {
  final dot = sourceName.lastIndexOf('.');
  final raw = dot <= 0 ? sourceName : sourceName.substring(0, dot);
  final cleaned = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return cleaned.isEmpty ? 'avatar' : cleaned;
}
