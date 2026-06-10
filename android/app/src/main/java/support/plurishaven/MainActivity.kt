package support.plurishaven

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import support.plurishaven.core.storage.HavenArchive
import support.plurishaven.core.storage.HavenState
import support.plurishaven.core.storage.LocalHavenStateStore

class MainActivity : ComponentActivity() {
	private lateinit var stateStore: LocalHavenStateStore

	private var havenState by mutableStateOf(HavenState.default())
	private var pendingExportText: String? = null
	private var fileStatus by mutableStateOf<String?>(null)

	private val createExportFile = registerForActivityResult(
		ActivityResultContracts.CreateDocument("application/json")
	) { uri ->
		if (uri == null) {
			fileStatus = "Export canceled"
			return@registerForActivityResult
		}

		val text = pendingExportText.orEmpty()
		runCatching {
			contentResolver.openOutputStream(uri)?.use { stream ->
				stream.write(text.toByteArray(Charsets.UTF_8))
			} ?: error("Could not open export file")
		}.onSuccess {
			fileStatus = "Export saved"
		}.onFailure { error ->
			fileStatus = "Export failed: ${error.message ?: "unknown error"}"
		}
	}

	private val openImportFile = registerForActivityResult(
		ActivityResultContracts.OpenDocument()
	) { uri ->
		if (uri == null) {
			fileStatus = "Import canceled"
			return@registerForActivityResult
		}

		runCatching {
			contentResolver.openInputStream(uri)?.bufferedReader()?.use { reader ->
				reader.readText()
			} ?: error("Could not open import file")
		}.mapCatching { text ->
			HavenArchive.fromJson(text)
		}.onSuccess { importedState ->
			saveState(
				state = importedState.withLog("import", "Imported from file"),
				status = "Import loaded"
			)
		}.onFailure { error ->
			fileStatus = "Import failed: ${error.message ?: "unknown error"}"
		}
	}

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		stateStore = LocalHavenStateStore(filesDir)
		havenState = stateStore.load()

		setContent {
			PlurisHavenApp(
				state = havenState,
				fileStatus = fileStatus,
				onImport = {
					openImportFile.launch(
						arrayOf(
							"application/json",
							"text/*",
							"application/octet-stream"
						)
					)
				},
				onSetFront = { label ->
					val nextFront = label.trim().ifBlank { "Unknown" }
					saveState(
						state = havenState
							.copy(currentFront = nextFront)
							.withLog("front", "Set front: $nextFront"),
						status = "Saved"
					)
				},
				onClearFront = {
					saveState(
						state = havenState
							.copy(currentFront = "None")
							.withLog("front", "Cleared front"),
						status = "Saved"
					)
				},
				onAddLog = { text ->
					val cleanText = text.trim()
					if (cleanText.isNotEmpty()) {
						saveState(
							state = havenState.withLog("note", cleanText),
							status = "Saved"
						)
					}
				},
				onExport = {
					pendingExportText = HavenArchive.toJson(havenState)
					createExportFile.launch("pluris-haven-export.json")
				}
			)
		}
	}

	private fun saveState(
		state: HavenState,
		status: String
	) {
		runCatching {
			stateStore.save(state)
		}.onSuccess {
			havenState = state
			fileStatus = status
		}.onFailure { error ->
			fileStatus = "Save failed: ${error.message ?: "unknown error"}"
		}
	}
}
