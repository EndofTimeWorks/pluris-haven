package support.plurishaven.core.storage

import org.json.JSONArray
import org.json.JSONObject
import java.io.File

data class HavenLog(
	val kind: String,
	val text: String,
	val createdAtEpochMillis: Long
)

data class HavenState(
	val currentFront: String,
	val logs: List<HavenLog>
) {
	companion object {
		fun default(): HavenState = HavenState(
			currentFront = "None",
			logs = listOf(
				HavenLog(
					kind = "note",
					text = "Local data only",
					createdAtEpochMillis = System.currentTimeMillis()
				)
			)
		)
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
	private const val Version = 1

	fun toJson(state: HavenState): String {
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
			.put("logs", logs)
			.toString(2)
	}

	fun fromJson(text: String): HavenState {
		val json = JSONObject(text)
		val currentFront = json.optString("currentFront", "None").ifBlank { "None" }
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
