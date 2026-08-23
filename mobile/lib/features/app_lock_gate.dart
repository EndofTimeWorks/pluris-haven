import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../platform/app_lock.dart';

/// Wraps the app so that, when enabled, the device's own screen lock
/// (biometric or PIN/pattern/password) must pass before content shows.
/// Re-locks whenever the app is backgrounded.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late bool _unlocked = !widget.enabled;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlock());
    }
  }

  @override
  void didUpdateWidget(covariant AppLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      setState(() => _unlocked = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlock());
    } else if (!widget.enabled && oldWidget.enabled) {
      setState(() => _unlocked = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;
    if (state == AppLifecycleState.paused && !_authenticating) {
      setState(() => _unlocked = false);
    } else if (state == AppLifecycleState.resumed &&
        !_unlocked &&
        !_authenticating) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlock());
    }
  }

  Future<void> _tryUnlock() async {
    if (!mounted || _unlocked || _authenticating) return;
    setState(() => _authenticating = true);
    // A device with no biometric or credential configured has nothing for
    // the lock to check against, so treat the setting as a no-op there
    // rather than showing an unlock screen that can never succeed.
    if (!await AppLock.isAvailable()) {
      if (mounted) {
        setState(() {
          _authenticating = false;
          _unlocked = true;
        });
      }
      return;
    }
    if (!mounted) return;
    final ok = await AppLock.authenticate(
      AppLocalizations.of(context).appLockReason,
    );
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (ok) _unlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: !_unlocked,
          child: TickerMode(enabled: _unlocked, child: widget.child),
        ),
        if (!_unlocked)
          Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appLockedTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.appLockedBody, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _authenticating ? null : _tryUnlock,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: Text(l10n.appLockUnlockButton),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
