package support.plurishaven.core.storage

import org.json.JSONArray
import org.json.JSONObject
import java.io.File

data class HavenLog(
	val kind: String,
	val text: String,
	val createdAtEpochMillis: Long
)

data class HavenFolder(
	val id: String,
	val name: String,
	val colorHex: String,
	val parentId: String?,
	val description: String,
	val emoji: String
)

data class HavenMember(
	val id: String,
	val name: String,
	val pronouns: String,
	val colorHex: String,
	val folderId: String?,
	val description: String,
	val avatarUrl: String,
	val pluralKitId: String,
	val archived: Boolean,
	val archivedReason: String,
	val customFields: Map<String, String>
)

data class HavenCustomField(
	val id: String,
	val name: String,
	val type: String,
	val order: Int
)

data class HavenNote(
	val id: String,
	val title: String,
	val body: String,
	val colorHex: String,
	val memberId: String?,
	val createdAtEpochMillis: Long,
	val markdown: Boolean
)

data class HavenFrontEvent(
	val id: String,
	val label: String,
	val memberIds: List<String>,
	val startedAtEpochMillis: Long,
	val endedAtEpochMillis: Long?
)

data class HavenState(
	val currentFront: String,
	val currentFrontMemberIds: List<String>,
	val currentFrontStartedAtEpochMillis: Long?,
	val members: List<HavenMember>,
	val folders: List<HavenFolder>,
	val customFields: List<HavenCustomField>,
	val notes: List<HavenNote>,
	val frontHistory: List<HavenFrontEvent>,
	val logs: List<HavenLog>
) {
	companion object {
		fun default(): HavenState = HavenState(
			currentFront = "None",
			currentFrontMemberIds = emptyList(),
			currentFrontStartedAtEpochMillis = null,
			members = emptyList(),
			folders = emptyList(),
			customFields = emptyList(),
			notes = emptyList(),
			frontHistory = emptyList(),
			logs = listOf(
				HavenLog(
					kind = "note",
					text = "Local data only",
					createdAtEpochMillis = System.currentTimeMillis()
				)
			)
		)
	}

	val currentFrontLabel: String
		get() {
			if (currentFrontMemberIds.isEmpty()) {
				return currentFront
			}

			val namesById = members.associateBy { it.id }
			return currentFrontMemberIds
				.mapNotNull { namesById[it]?.name }
				.ifEmpty { listOf(currentFront) }
				.joinToString(", ")
		}

	fun withLog(
		kind: String,
		text: String,
		nowEpochMillis: Long = System.currentTimeMillis()
	): HavenState = copy(
		logs = listOf(
			HavenLog(
				kind = kind,
				text = text,
				createdAtEpochMillis = nowEpochMillis
			)
		) + logs
	)

	fun withCurrentFront(
		label: String,
		memberIds: List<String>,
		nowEpochMillis: Long = System.currentTimeMillis()
	): HavenState {
		val cleanLabel = label.trim().ifBlank { "None" }
		val cleanMemberIds = memberIds.distinct()
		val isCleared = cleanLabel == "None" && cleanMemberIds.isEmpty()

		if (
			cleanLabel == currentFront &&
			cleanMemberIds == currentFrontMemberIds &&
			currentFrontStartedAtEpochMillis != null
		) {
			return this
		}

		val closedHistory = frontHistory.mapIndexed { index, event ->
			if (index == 0 && event.endedAtEpochMillis == null) {
				event.copy(endedAtEpochMillis = nowEpochMillis)
			} else {
				event
			}
		}

		val nextHistory = if (isCleared) {
			closedHistory
		} else {
			listOf(
				HavenFrontEvent(
					id = "front-$nowEpochMillis",
					label = cleanLabel,
					memberIds = cleanMemberIds,
					startedAtEpochMillis = nowEpochMillis,
					endedAtEpochMillis = null
				)
			) + closedHistory
		}

		return copy(
			currentFront = cleanLabel,
			currentFrontMemberIds = cleanMemberIds,
			currentFrontStartedAtEpochMillis = if (isCleared) null else nowEpochMillis,
			frontHistory = nextHistory
		)
	}
}

class LocalHavenStateStore(
	filesDir: File
) {
	private val stateFile = File(filesDir, "pluris-haven-state.json")

	fun load(): HavenState {
		if (!stateFile.exists()) {
			return HavenState.default()
		}

		return runCatching {
			HavenArchive.fromJson(stateFile.readText())
		}.getOrElse {
			HavenState.default()
		}
	}

	fun save(state: HavenState) {
		val tempFile = File(stateFile.parentFile, "${stateFile.name}.tmp")
		tempFile.writeText(HavenArchive.toJson(state))
		if (!tempFile.renameTo(stateFile)) {
			tempFile.copyTo(stateFile, overwrite = true)
			tempFile.delete()
		}
	}
}

object HavenArchive {
	private const val Format = "pluris-haven/offline"
	private const val Version = 1

	fun toJson(state: HavenState): String {
		val folders = JSONArray()
		state.folders.forEach { folder ->
			folders.put(
				JSONObject()
					.put("id", folder.id)
					.put("name", folder.name)
					.put("color", folder.colorHex)
					.put("parentId", folder.parentId)
					.put("description", folder.description)
					.put("emoji", folder.emoji)
			)
		}

		val members = JSONArray()
		state.members.forEach { member ->
			members.put(
				JSONObject()
					.put("id", member.id)
					.put("name", member.name)
					.put("pronouns", member.pronouns)
					.put("color", member.colorHex)
					.put("folderId", member.folderId)
					.put("description", member.description)
					.put("avatarUrl", member.avatarUrl)
					.put("pluralKitId", member.pluralKitId)
					.put("archived", member.archived)
					.put("archivedReason", member.archivedReason)
					.put("customFields", JSONObject(member.customFields))
			)
		}

		val customFields = JSONArray()
		state.customFields.forEach { field ->
			customFields.put(
				JSONObject()
					.put("id", field.id)
					.put("name", field.name)
					.put("type", field.type)
					.put("order", field.order)
			)
		}

		val notes = JSONArray()
		state.notes.forEach { note ->
			notes.put(
				JSONObject()
					.put("id", note.id)
					.put("title", note.title)
					.put("body", note.body)
					.put("color", note.colorHex)
					.put("memberId", note.memberId)
					.put("createdAt", note.createdAtEpochMillis)
					.put("markdown", note.markdown)
			)
		}

		val currentFrontMemberIds = JSONArray()
		state.currentFrontMemberIds.forEach { id ->
			currentFrontMemberIds.put(id)
		}

		val frontHistory = JSONArray()
		state.frontHistory.forEach { event ->
			val memberIds = JSONArray()
			event.memberIds.forEach { id ->
				memberIds.put(id)
			}
			frontHistory.put(
				JSONObject()
					.put("id", event.id)
					.put("label", event.label)
					.put("memberIds", memberIds)
					.put("startedAt", event.startedAtEpochMillis)
					.put("endedAt", event.endedAtEpochMillis)
			)
		}

		val logs = JSONArray()
		state.logs.forEach { log ->
			logs.put(
				JSONObject()
					.put("kind", log.kind)
					.put("text", log.text)
					.put("createdAt", log.createdAtEpochMillis)
			)
		}

		return JSONObject()
			.put("format", Format)
			.put("version", Version)
			.put("currentFront", state.currentFront)
			.put("currentFrontMemberIds", currentFrontMemberIds)
			.put("currentFrontStartedAt", state.currentFrontStartedAtEpochMillis)
			.put("folders", folders)
			.put("members", members)
			.put("customFields", customFields)
			.put("notes", notes)
			.put("frontHistory", frontHistory)
			.put("logs", logs)
			.toString(2)
	}

	fun fromJson(text: String): HavenState {
		val json = JSONObject(text)
		val currentFront = json.optString("currentFront", "None").ifBlank { "None" }
		val folders = mutableListOf<HavenFolder>()
		val jsonFolders = json.optJSONArray("folders") ?: JSONArray()
		for (index in 0 until jsonFolders.length()) {
			val item = jsonFolders.optJSONObject(index) ?: continue
			val name = item.optString("name", "").trim()
			if (name.isBlank()) {
				continue
			}

			folders += HavenFolder(
				id = item.requireString("id", "folder-$index"),
				name = name,
				colorHex = item.requireString("color", "#0F766E"),
				parentId = item.optionalString("parentId"),
				description = item.optionalString("description").orEmpty(),
				emoji = item.optionalString("emoji").orEmpty()
			)
		}

		val members = mutableListOf<HavenMember>()
		val jsonMembers = json.optJSONArray("members") ?: JSONArray()
		for (index in 0 until jsonMembers.length()) {
			val item = jsonMembers.optJSONObject(index) ?: continue
			val name = item.optString("name", "").trim()
			if (name.isBlank()) {
				continue
			}

			members += HavenMember(
				id = item.requireString("id", "member-$index"),
				name = name,
				pronouns = item.optString("pronouns", "").trim(),
				colorHex = item.requireString("color", "#4F46E5"),
				folderId = item.optionalString("folderId"),
				description = item.optionalString("description").orEmpty(),
				avatarUrl = item.optionalString("avatarUrl").orEmpty(),
				pluralKitId = item.optionalString("pluralKitId").orEmpty(),
				archived = item.optBoolean("archived", false),
				archivedReason = item.optionalString("archivedReason").orEmpty(),
				customFields = item.optJSONObject("customFields").toStringMap()
			)
		}

		val customFields = mutableListOf<HavenCustomField>()
		val jsonCustomFields = json.optJSONArray("customFields") ?: JSONArray()
		for (index in 0 until jsonCustomFields.length()) {
			val item = jsonCustomFields.optJSONObject(index) ?: continue
			val name = item.optString("name", "").trim()
			if (name.isBlank()) {
				continue
			}

			customFields += HavenCustomField(
				id = item.requireString("id", "field-$index"),
				name = name,
				type = item.requireString("type", "text"),
				order = item.optInt("order", index)
			)
		}

		val notes = mutableListOf<HavenNote>()
		val jsonNotes = json.optJSONArray("notes") ?: JSONArray()
		for (index in 0 until jsonNotes.length()) {
			val item = jsonNotes.optJSONObject(index) ?: continue
			val body = item.optString("body", "").trim()
			if (body.isBlank()) {
				continue
			}

			notes += HavenNote(
				id = item.requireString("id", "note-$index"),
				title = item.optionalString("title").orEmpty(),
				body = body,
				colorHex = item.requireString("color", "#4F46E5"),
				memberId = item.optionalString("memberId"),
				createdAtEpochMillis = item.optLong("createdAt", System.currentTimeMillis()),
				markdown = item.optBoolean("markdown", false)
			)
		}

		val currentFrontMemberIds = mutableListOf<String>()
		val jsonFrontIds = json.optJSONArray("currentFrontMemberIds") ?: JSONArray()
		for (index in 0 until jsonFrontIds.length()) {
			val id = jsonFrontIds.optString(index, "").trim()
			if (id.isNotBlank()) {
				currentFrontMemberIds += id
			}
		}

		val frontHistory = mutableListOf<HavenFrontEvent>()
		val jsonFrontHistory = json.optJSONArray("frontHistory") ?: JSONArray()
		for (index in 0 until jsonFrontHistory.length()) {
			val item = jsonFrontHistory.optJSONObject(index) ?: continue
			val memberIds = mutableListOf<String>()
			val jsonMemberIds = item.optJSONArray("memberIds") ?: JSONArray()
			for (memberIndex in 0 until jsonMemberIds.length()) {
				val id = jsonMemberIds.optString(memberIndex, "").trim()
				if (id.isNotBlank()) {
					memberIds += id
				}
			}

			val startedAt = item.optLong("startedAt", 0L)
			if (startedAt > 0L) {
				val endedAt = if (item.isNull("endedAt")) null else item.optLong("endedAt")
				frontHistory += HavenFrontEvent(
					id = item.optString("id", "front-$index").ifBlank { "front-$index" },
					label = item.optString("label", "Unknown").ifBlank { "Unknown" },
					memberIds = memberIds,
					startedAtEpochMillis = startedAt,
					endedAtEpochMillis = endedAt
				)
			}
		}

		val logs = mutableListOf<HavenLog>()
		val jsonLogs = json.optJSONArray("logs") ?: JSONArray()

		for (index in 0 until jsonLogs.length()) {
			val item = jsonLogs.optJSONObject(index) ?: continue
			val logText = item.optString("text", "").ifBlank { "(empty)" }
			logs += HavenLog(
				kind = item.optString("kind", "note").ifBlank { "note" },
				text = logText,
				createdAtEpochMillis = item.optLong("createdAt", System.currentTimeMillis())
			)
		}

		return HavenState(
			currentFront = currentFront,
			currentFrontMemberIds = currentFrontMemberIds,
			currentFrontStartedAtEpochMillis = json.optLongOrNull("currentFrontStartedAt"),
			members = members,
			folders = folders,
			customFields = customFields,
			notes = notes,
			frontHistory = frontHistory,
			logs = logs.ifEmpty {
				listOf(
					HavenLog(
						kind = "note",
						text = "Imported empty log",
						createdAtEpochMillis = System.currentTimeMillis()
					)
				)
			}
		)
	}
}

private fun JSONObject.requireString(
	name: String,
	fallback: String
): String = optionalString(name) ?: fallback

private fun JSONObject.optionalString(name: String): String? {
	return optString(name, "").trim().ifBlank { null }
}

private fun JSONObject.optLongOrNull(name: String): Long? {
	return if (isNull(name)) {
		null
	} else {
		optLong(name)
	}
}

private fun JSONObject?.toStringMap(): Map<String, String> {
	if (this == null) {
		return emptyMap()
	}

	val result = mutableMapOf<String, String>()
	keys().forEach { key ->
		result[key] = optString(key, "")
	}
	return result
}
