package support.plurishaven.core.model

data class PluralSystem(
	val id: String,
	val displayName: String,
	val languageTag: String
)

data class Member(
	val id: String,
	val systemId: String,
	val displayName: String,
	val pronouns: String?,
	val colorArgb: Long?,
	val archived: Boolean
)

data class FrontState(
	val id: String,
	val systemId: String,
	val label: String,
	val memberIds: List<String>,
	val startedAtEpochMillis: Long?
)

enum class CoreModule {
	Logs,
	Chat,
	Archive,
	Journal,
	Polls,
	CustomFronts,
	CustomTerms,
	Languages,
	Folders,
	Export,
	SimplyPluralImport,
	PluralKitImport,
	StickyNotification,
	Friends,
	Statistics
}
