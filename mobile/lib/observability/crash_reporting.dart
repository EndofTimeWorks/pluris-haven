import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN');
const _sentryEnabled = bool.fromEnvironment('SENTRY_ENABLED');
const _sentryEnvironment = String.fromEnvironment('SENTRY_ENVIRONMENT');

@visibleForTesting
bool crashReportingEnabled({
  required bool isReleaseBuild,
  required bool sentryEnabled,
  required String sentryDsn,
}) => isReleaseBuild && sentryEnabled && sentryDsn.isNotEmpty;

Future<void> runWithCrashReporting(void Function() appRunner) async {
  if (!crashReportingEnabled(
    isReleaseBuild: kReleaseMode,
    sentryEnabled: _sentryEnabled,
    sentryDsn: _sentryDsn,
  )) {
    appRunner();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.environment = _sentryEnvironment.isEmpty
          ? 'production'
          : _sentryEnvironment;
      options.sendDefaultPii = false;
      options.maxBreadcrumbs = 0;
      options.beforeBreadcrumb = (_, _) => null;
      options.enableAutoSessionTracking = false;
      options.enableAutoNativeBreadcrumbs = false;
      options.enableAutoPerformanceTracing = false;
      options.enableUserInteractionBreadcrumbs = false;
      options.enableUserInteractionTracing = false;
      options.enableAppHangTracking = false;
      options.enableWatchdogTerminationTracking = false;
      options.enableFramesTracking = false;
      options.enableNdkScopeSync = false;
      options.tracesSampleRate = 0;
      options.attachScreenshot = false;
      options.reportViewHierarchyIdentifiers = false;
      options.sendClientReports = false;
    },
    appRunner: () {
      Sentry.configureScope((scope) => scope.setUser(SentryUser()));
      appRunner();
    },
  );
}
