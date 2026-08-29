import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/observability/crash_reporting.dart';

void main() {
  test('crash reporting requires an explicitly configured release build', () {
    expect(
      crashReportingEnabled(
        isReleaseBuild: false,
        sentryEnabled: true,
        sentryDsn: 'https://example.ingest.sentry.io/1',
      ),
      isFalse,
    );
    expect(
      crashReportingEnabled(
        isReleaseBuild: true,
        sentryEnabled: false,
        sentryDsn: 'https://example.ingest.sentry.io/1',
      ),
      isFalse,
    );
    expect(
      crashReportingEnabled(
        isReleaseBuild: true,
        sentryEnabled: true,
        sentryDsn: '',
      ),
      isFalse,
    );
    expect(
      crashReportingEnabled(
        isReleaseBuild: true,
        sentryEnabled: true,
        sentryDsn: 'https://example.ingest.sentry.io/1',
      ),
      isTrue,
    );
  });
}
