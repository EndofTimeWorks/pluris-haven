package support.plurishaven.core.security

data class OnlineServiceDisclosure(
	val serviceName: String,
	val leavesDevice: Set<DataCategory>,
	val readableByPlurisHavenServer: Boolean,
	val readableByThirdParty: Boolean,
	val disconnectBehavior: String,
	val remoteRetention: String
)

enum class DataClass {
	LocalPrivate,
	IntegrationReadable
}

enum class DataCategory(val dataClass: DataClass) {
	FrontStatus(DataClass.IntegrationReadable),
	SelectedMemberProfile(DataClass.IntegrationReadable),
	ProxyMetadata(DataClass.IntegrationReadable),
	JournalContent(DataClass.LocalPrivate),
	ChatMessages(DataClass.LocalPrivate),
	PollContent(DataClass.LocalPrivate),
	DetailedLogs(DataClass.LocalPrivate),
	ArchiveNotes(DataClass.LocalPrivate)
}

object SecurityPolicy {
	val baselineRequirements = listOf(
		"No account required for local use",
		"Network disabled until an online service is connected",
		"Sensitive data encrypted at rest before real user data is stored",
		"Key material stored in Android Keystore where possible",
		"Plaintext private data excluded from logs, backups, crash reports, and analytics",
		"Import and export available offline"
	)
}
