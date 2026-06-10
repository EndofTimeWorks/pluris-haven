package support.plurishaven.core.storage

import org.json.JSONArray
import org.json.JSONObject
import java.io.File

data class HavenLog(
	val kind: String,
	val text: String,
	val createdAtEpochMillis: Long
)

data class HavenMember(
	val id: String,
	val name: String,
	val pronouns: String,
	val colorHex: String
)

data class HavenState(
	val currentFront: String,
	val currentFrontMemberIds: List<String>,
	val members: List<HavenMember>,
	val logs: List<HavenLog>
) {
	companion object {
		fun default(): HavenState = HavenState(
			currentFront = "None",
			currentFrontMemberIds = emptyList(),
			members = emptyList(),
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
	private const val Format = "pluris-haven/basic"
	private const val Version = 2

	fun toJson(state: HavenState): String {
		val members = JSONArray()
		state.members.forEach { member ->
			members.put(
				JSONObject()
					.put("id", member.id)
					.put("name", member.name)
					.put("pronouns", member.pronouns)
					.put("color", member.colorHex)
			)
		}

		val currentFrontMemberIds = JSONArray()
		state.currentFrontMemberIds.forEach { id ->
			currentFrontMemberIds.put(id)
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
			.put("members", members)
			.put("logs", logs)
			.toString(2)
	}

	fun fromJson(text: String): HavenState {
		val json = JSONObject(text)
		val currentFront = json.optString("currentFront", "None").ifBlank { "None" }
		val members = mutableListOf<HavenMember>()
		val jsonMembers = json.optJSONArray("members") ?: JSONArray()
		for (index in 0 until jsonMembers.length()) {
			val item = jsonMembers.optJSONObject(index) ?: continue
			val name = item.optString("name", "").trim()
			if (name.isBlank()) {
				continue
			}

			members += HavenMember(
				id = item.optString("id", "member-$index").ifBlank { "member-$index" },
				name = name,
				pronouns = item.optString("pronouns", "").trim(),
				colorHex = item.optString("color", "#4F46E5").ifBlank { "#4F46E5" }
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
			members = members,
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
