package support.plurishaven.core.archive

data class PlurisArchiveManifest(
	val schemaVersion: Int,
	val appVersion: String,
	val createdAtEpochMillis: Long,
	val encrypted: Boolean,
	val includesServiceTokens: Boolean,
	val sections: Set<ArchiveSection>,
	val importedSources: List<ImportProvenance>
) {
	companion object {
		const val CURRENT_SCHEMA_VERSION = 1
	}
}

data class ImportProvenance(
	val source: ImportSource,
	val importedAtEpochMillis: Long,
	val sourceLabel: String?
)

enum class ImportSource {
	PlurisHaven,
	SimplyPlural,
	PluralKit
}

enum class ArchiveSection {
	Systems,
	Members,
	Fronts,
	Logs,
	Chats,
	Journals,
	Polls,
	Folders,
	CustomTerms,
	Archives,
	StatisticsInputs,
	ServiceConnectionMetadata
}
