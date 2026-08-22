part of 'home_page.dart';

class ServerAccountPanel extends StatefulWidget {
  const ServerAccountPanel({super.key, required this.controller});

  final ServerAccountController? controller;

  @override
  State<ServerAccountPanel> createState() => _ServerAccountPanelState();
}

class _ServerAccountPanelState extends State<ServerAccountPanel> {
  final _serverController = TextEditingController();

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;
    if (controller == null) {
      return SpCard(
        outlined: true,
        child: Text(l10n.serverAccountsUnavailable),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SpCard(
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpSectionHeader(title: l10n.optionalServerAccountTitle),
              const SizedBox(height: 8),
              if (!controller.connected) ...[
                Text(
                  l10n.serverConnectDescription,
                  style: const TextStyle(color: _spMuted, height: 1.35),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('server-url-field'),
                  controller: _serverController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.serverUrlLabel,
                    hintText: 'https://haven.example',
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const ValueKey('connect-server-button'),
                  onPressed: controller.busy
                      ? null
                      : () => controller.connect(_serverController.text),
                  icon: const Icon(Icons.dns_outlined),
                  label: Text(l10n.connectServerButton),
                ),
              ] else ...[
                Text(
                  controller.descriptor?.name ?? l10n.connectedServerFallback,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  controller.serverUri.toString(),
                  style: const TextStyle(color: _spMuted),
                ),
                const SizedBox(height: 12),
                if (!controller.signedIn)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        key: const ValueKey('server-login-button'),
                        onPressed: controller.busy
                            ? null
                            : () =>
                                  _showAuthentication(context, register: false),
                        child: Text(l10n.signInButton),
                      ),
                      OutlinedButton(
                        key: const ValueKey('server-register-button'),
                        onPressed:
                            controller.busy ||
                                controller.descriptor?.registrationEnabled !=
                                    true
                            ? null
                            : () =>
                                  _showAuthentication(context, register: true),
                        child: Text(l10n.createAccountButton),
                      ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : controller.disconnect,
                        child: Text(l10n.disconnectButton),
                      ),
                    ],
                  )
                else ...[
                  Text(
                    controller.account?.displayName ?? l10n.accountFallback,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    controller.account?.email ?? '',
                    style: const TextStyle(color: _spMuted),
                  ),
                  const SizedBox(height: 12),
                  for (final session in controller.sessions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        session.current
                            ? Icons.phone_android
                            : Icons.devices_other,
                      ),
                      title: Text(session.deviceName),
                      subtitle: Text(
                        session.current
                            ? l10n.thisDeviceLabel
                            : l10n.activeServerSessionLabel,
                      ),
                      trailing: session.current
                          ? null
                          : IconButton(
                              tooltip: l10n.revokeSessionTooltip,
                              onPressed: controller.busy
                                  ? null
                                  : () => controller.revokeSession(session.id),
                              icon: const Icon(Icons.logout),
                            ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.securityHistoryTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.securityHistoryDescription,
                    style: const TextStyle(color: _spMuted, height: 1.35),
                  ),
                  if (controller.securityEvents.isEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(l10n.securityHistoryEmpty),
                    )
                  else
                    for (final event in controller.securityEvents)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.shield_outlined),
                        title: Text(_securityEventLabel(l10n, event.eventType)),
                        subtitle: Text(
                          _securityEventTime(context, event.occurredAt),
                        ),
                      ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: controller.busy
                            ? null
                            : controller.refreshAll,
                        child: Text(l10n.refreshButton),
                      ),
                      OutlinedButton(
                        key: const ValueKey('change-server-password-button'),
                        onPressed: controller.busy
                            ? null
                            : () => _showChangePassword(context),
                        child: Text(l10n.changePasswordButton),
                      ),
                      OutlinedButton(
                        onPressed: controller.busy ? null : controller.logout,
                        child: Text(l10n.signOutButton),
                      ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => _confirmDeleteAccount(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: Text(l10n.deleteServerAccountButton),
                      ),
                    ],
                  ),
                ],
              ],
              if (controller.busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (controller.error != null) ...[
                const SizedBox(height: 10),
                _ServerMessage(controller.error!, error: true),
              ],
              if (controller.status != null) ...[
                const SizedBox(height: 10),
                _ServerMessage(controller.status!),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAuthentication(
    BuildContext context, {
    required bool register,
  }) {
    final controller = widget.controller!;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ServerAuthenticationSheet(
        register: register,
        controller: controller,
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteServerAccountTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteServerAccountBody),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('delete-account-password-field'),
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.currentPasswordLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButtonLabel),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-server-account-button'),
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: Text(l10n.deleteAccountButton),
          ),
        ],
      ),
    );
    passwordController.dispose();
    if (password != null && password.isNotEmpty && mounted) {
      await widget.controller!.deleteAccount(password);
    }
  }

  Future<void> _showChangePassword(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _ChangePasswordSheet(controller: widget.controller!),
    );
  }
}

String _securityEventLabel(AppLocalizations l10n, String eventType) {
  return switch (eventType) {
    'signed_out' => l10n.securityEventSignedOut,
    'password_changed' => l10n.securityEventPasswordChanged,
    'session_revoked' => l10n.securityEventSessionRevoked,
    'backup_recovery_started' => l10n.securityEventBackupRecoveryStarted,
    'backup_deleted' => l10n.securityEventBackupDeleted,
    'account_deleted' => l10n.securityEventAccountDeleted,
    _ => l10n.securityEventUnknown,
  };
}

String _securityEventTime(BuildContext context, DateTime occurredAt) {
  final local = occurredAt.toLocal();
  final material = MaterialLocalizations.of(context);
  return '${material.formatShortDate(local)} '
      '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.controller});

  final ServerAccountController controller;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.changePasswordTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('current-server-password-field'),
                  controller: _currentPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.currentPasswordLabel,
                  ),
                  validator: (value) => value?.isNotEmpty == true
                      ? null
                      : l10n.requiredFieldError,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const ValueKey('new-server-password-field'),
                  controller: _newPassword,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.newPasswordLabel),
                  validator: (value) => (value?.length ?? 0) >= 12
                      ? null
                      : l10n.passwordLengthError,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const ValueKey('confirm-server-password-field'),
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewPasswordLabel,
                  ),
                  validator: (value) => value == _newPassword.text
                      ? null
                      : l10n.passwordsDoNotMatchError,
                ),
                if (widget.controller.error != null) ...[
                  const SizedBox(height: 10),
                  _ServerMessage(widget.controller.error!, error: true),
                ],
                const SizedBox(height: 14),
                FilledButton(
                  key: const ValueKey('submit-change-server-password-button'),
                  onPressed: widget.controller.busy ? null : _submit,
                  child: Text(l10n.changePasswordButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    await widget.controller.changePassword(
      currentPassword: _currentPassword.text,
      newPassword: _newPassword.text,
    );
    if (!mounted || widget.controller.error != null) return;
    final message = AppLocalizations.of(context).passwordChangedMessage;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ServerAuthenticationSheet extends StatefulWidget {
  const _ServerAuthenticationSheet({
    required this.register,
    required this.controller,
  });

  final bool register;
  final ServerAccountController controller;

  @override
  State<_ServerAuthenticationSheet> createState() =>
      _ServerAuthenticationSheetState();
}

class _ServerAuthenticationSheetState
    extends State<_ServerAuthenticationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _deviceName = TextEditingController(text: 'Pluris Haven mobile');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    _deviceName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.register
                      ? l10n.createServerAccountTitle
                      : l10n.signInButton,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (widget.register) ...[
                  TextFormField(
                    key: const ValueKey('server-display-name-field'),
                    controller: _displayName,
                    decoration: InputDecoration(
                      labelText: l10n.displayNameLabel,
                    ),
                    validator: (value) => _required(value, l10n),
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  key: const ValueKey('server-email-field'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l10n.emailLabel),
                  validator: (value) => value?.contains('@') == true
                      ? null
                      : l10n.invalidEmailError,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const ValueKey('server-password-field'),
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.passwordLabel),
                  validator: (value) =>
                      widget.register && (value?.length ?? 0) < 12
                      ? l10n.passwordLengthError
                      : _required(value, l10n),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const ValueKey('server-device-name-field'),
                  controller: _deviceName,
                  decoration: InputDecoration(labelText: l10n.deviceNameLabel),
                  validator: (value) => _required(value, l10n),
                ),
                if (widget.controller.error != null) ...[
                  const SizedBox(height: 10),
                  _ServerMessage(widget.controller.error!, error: true),
                ],
                const SizedBox(height: 14),
                FilledButton(
                  key: const ValueKey('submit-server-auth-button'),
                  onPressed: widget.controller.busy ? null : _submit,
                  child: Text(
                    widget.register
                        ? l10n.createAccountButton
                        : l10n.signInButton,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value, AppLocalizations l10n) {
    return value?.trim().isNotEmpty == true ? null : l10n.requiredFieldError;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (widget.register) {
      await widget.controller.register(
        email: _email.text,
        password: _password.text,
        displayName: _displayName.text,
        deviceName: _deviceName.text,
      );
    } else {
      await widget.controller.login(
        email: _email.text,
        password: _password.text,
        deviceName: _deviceName.text,
      );
    }
    if (widget.controller.signedIn && mounted) {
      Navigator.pop(context);
    }
  }
}

class ServerBackupPanel extends StatefulWidget {
  const ServerBackupPanel({
    super.key,
    required this.repository,
    required this.controller,
  });

  final HavenRepository repository;
  final ServerAccountController? controller;

  @override
  State<ServerBackupPanel> createState() => _ServerBackupPanelState();
}

class _ServerBackupPanelState extends State<ServerBackupPanel> {
  String? _restoringSnapshotId;
  String? _restoreMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;
    if (controller == null) {
      return SpCard(outlined: true, child: Text(l10n.onlineBackupUnavailable));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SpCard(
        outlined: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SpSectionHeader(title: l10n.encryptedOnlineBackupTitle),
            const SizedBox(height: 8),
            Text(
              controller.signedIn
                  ? l10n.backupEncryptionDescription
                  : l10n.backupSignInDescription,
              style: const TextStyle(color: _spMuted),
            ),
            if (controller.uploadTotalChunks > 0 && controller.busy) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value:
                    controller.uploadCompletedChunks /
                    controller.uploadTotalChunks,
                semanticsLabel: l10n.backupUploadProgressLabel,
                semanticsValue: l10n.backupUploadProgressValue(
                  controller.uploadCompletedChunks,
                  controller.uploadTotalChunks,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('upload-encrypted-backup-button'),
              onPressed:
                  !controller.signedIn ||
                      controller.busy ||
                      widget.repository is! LocalHavenRepository
                  ? null
                  : _upload,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(l10n.createUploadSnapshotButton),
            ),
            const SizedBox(height: 8),
            for (final backup in controller.backups)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  backup.complete
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_sync_outlined,
                ),
                title: Text(backup.snapshotId),
                subtitle: Text(
                  l10n.backupSnapshotProgress(
                    backup.uploadedChunks,
                    backup.chunkCount,
                    backup.uploadedBytes,
                    backup.totalBytes,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.restoreEncryptedBackupButton,
                      onPressed:
                          !backup.complete ||
                              _restoringSnapshotId != null ||
                              widget.repository is! LocalHavenRepository
                          ? null
                          : () => _restore(backup),
                      icon: const Icon(Icons.restore_rounded),
                    ),
                    IconButton(
                      tooltip: l10n.deleteEncryptedBackupTooltip,
                      onPressed: controller.busy
                          ? null
                          : () => confirmDelete(
                              context,
                              title: l10n.deleteEncryptedBackupTitle,
                              body: l10n.deleteEncryptedBackupBody,
                              onDelete: () =>
                                  controller.deleteBackup(backup.snapshotId),
                            ),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                onTap:
                    backup.complete &&
                        _restoringSnapshotId == null &&
                        widget.repository is LocalHavenRepository
                    ? () => _restore(backup)
                    : null,
              ),
            if (_restoreMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _restoreMessage!,
                style: TextStyle(
                  color: _restoreMessage!.startsWith('Could not')
                      ? Theme.of(context).colorScheme.error
                      : _spMuted,
                ),
              ),
            ],
            if (controller.error != null)
              _ServerMessage(controller.error!, error: true),
            if (controller.status != null) _ServerMessage(controller.status!),
          ],
        ),
      ),
    );
  }

  Future<void> _upload() async {
    final repository = widget.repository as LocalHavenRepository;
    final now = DateTime.now().toUtc();
    final snapshot = await repository.buildEncryptedBackupSnapshot(
      snapshotId: 'mobile-${now.microsecondsSinceEpoch}',
      createdAt: now,
    );
    await widget.controller!.uploadBackup(snapshot);
  }

  Future<void> _restore(ServerBackupSnapshot backup) async {
    final repository = widget.repository as LocalHavenRepository;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreEncryptedBackupTitle),
        content: Text(l10n.restoreEncryptedBackupBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.restoreEncryptedBackupConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _restoringSnapshotId = backup.snapshotId;
      _restoreMessage = l10n.restoringEncryptedBackup;
    });
    try {
      final snapshot = await widget.controller!.downloadBackup(backup);
      final archiveJson = await snapshot.restoreArchiveJson(repository.crypto);
      final rehearsal = await repository.rehearseLocalArchiveRestore(
        archiveJson,
        strategy: ImportConflictStrategy.update,
        fileName: '${backup.snapshotId}.json',
        source: ImportSource.plurisHavenArchive,
      );
      if (!rehearsal.canRestore) {
        throw StateError(rehearsal.error ?? 'Restore rehearsal failed.');
      }
      await repository.importLocalArchiveJson(
        archiveJson,
        strategy: ImportConflictStrategy.update,
        fileName: '${backup.snapshotId}.json',
        source: ImportSource.plurisHavenArchive,
      );
      if (!mounted) return;
      setState(() {
        _restoreMessage = AppLocalizations.of(context).encryptedBackupRestored;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _restoreMessage = AppLocalizations.of(
          context,
        ).encryptedBackupRestoreFailed(error.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _restoringSnapshotId = null;
        });
      }
    }
  }
}

class ServerFriendsPage extends StatefulWidget {
  const ServerFriendsPage({super.key, required this.controller});

  final ServerAccountController? controller;

  @override
  State<ServerFriendsPage> createState() => _ServerFriendsPageState();
}

class _ServerFriendsPageState extends State<ServerFriendsPage> {
  final _friendCode = TextEditingController();

  @override
  void dispose() {
    _friendCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;
    if (controller == null || !controller.signedIn) {
      return OfflineFeaturePage(
        title: l10n.friendsLabel,
        body: l10n.friendsSignInBody,
        rows: [
          SpSettingsRow(
            l10n.localDataLabel,
            l10n.notSharedValue,
            interactive: false,
          ),
          SpSettingsRow(l10n.requestsLabel, l10n.offValue, interactive: false),
        ],
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.descriptor?.friendsEnabled != true) {
          return OfflineFeaturePage(
            title: l10n.friendsLabel,
            body: l10n.friendsDisabledBody,
            rows: [
              SpSettingsRow(
                l10n.localDataLabel,
                l10n.notSharedValue,
                interactive: false,
              ),
              SpSettingsRow(
                l10n.requestsLabel,
                l10n.serverDisabledValue,
                interactive: false,
              ),
            ],
          );
        }
        return SpPage(
          children: [
            SpCard(
              outlined: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(title: l10n.friendCodeTitle),
                  const SizedBox(height: 8),
                  SelectableText(
                    controller.friendCode ?? l10n.rotateFriendCodePrompt,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: controller.busy
                        ? null
                        : controller.rotateFriendCode,
                    child: Text(l10n.rotateFriendCodeButton),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('friend-code-field'),
                    controller: _friendCode,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.someoneElsesCodeLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const ValueKey('send-friend-request-button'),
                    onPressed: controller.busy
                        ? null
                        : () => controller.sendFriendRequest(_friendCode.text),
                    child: Text(l10n.sendRequestButton),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(title: l10n.pendingRequestsTitle),
                  if (controller.friendRequests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.noPendingRequests,
                        style: const TextStyle(color: _spMuted),
                      ),
                    ),
                  for (final request in controller.friendRequests)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(request.user.displayName),
                      subtitle: Text(request.direction),
                      trailing: request.direction == 'incoming'
                          ? Wrap(
                              children: [
                                IconButton(
                                  tooltip: l10n.acceptRequestTooltip,
                                  onPressed: controller.busy
                                      ? null
                                      : () => controller.respondToFriendRequest(
                                          request.id,
                                          'accept',
                                        ),
                                  icon: const Icon(Icons.check),
                                ),
                                IconButton(
                                  tooltip: l10n.declineRequestTooltip,
                                  onPressed: controller.busy
                                      ? null
                                      : () => controller.respondToFriendRequest(
                                          request.id,
                                          'decline',
                                        ),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            )
                          : IconButton(
                              tooltip: l10n.cancelRequestTooltip,
                              onPressed: controller.busy
                                  ? null
                                  : () => controller.respondToFriendRequest(
                                      request.id,
                                      'cancel',
                                    ),
                              icon: const Icon(Icons.cancel_outlined),
                            ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(title: l10n.friendsLabel),
                  if (controller.friends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.noFriendsYet,
                        style: const TextStyle(color: _spMuted),
                      ),
                    ),
                  for (final friend in controller.friends)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(friend.user.displayName),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'remove') {
                            await confirmDelete(
                              context,
                              title: l10n.removeFriendTitle,
                              body: l10n.removeFriendBody,
                              onDelete: () =>
                                  controller.removeFriend(friend.friendshipId),
                            );
                          } else if (action == 'block') {
                            await confirmDelete(
                              context,
                              title: l10n.blockUserTitle(
                                friend.user.displayName,
                              ),
                              body: l10n.blockUserBody,
                              onDelete: () =>
                                  controller.blockUser(friend.user.id),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(l10n.removeFriendButton),
                          ),
                          PopupMenuItem(
                            value: 'block',
                            child: Text(l10n.blockUserButton),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(title: l10n.blockedUsersTitle),
                  if (controller.blocks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.noBlockedUsers,
                        style: const TextStyle(color: _spMuted),
                      ),
                    ),
                  for (final block in controller.blocks)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(block.user.displayName),
                      trailing: TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => controller.unblockUser(block.user.id),
                        child: Text(l10n.unblockButton),
                      ),
                    ),
                ],
              ),
            ),
            if (controller.error != null) ...[
              const SizedBox(height: 10),
              _ServerMessage(controller.error!, error: true),
            ],
            if (controller.status != null) ...[
              const SizedBox(height: 10),
              _ServerMessage(controller.status!),
            ],
          ],
        );
      },
    );
  }
}

class _ServerMessage extends StatelessWidget {
  const _ServerMessage(this.message, {this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(
          color: error ? Theme.of(context).colorScheme.error : _spMuted,
        ),
      ),
    );
  }
}
