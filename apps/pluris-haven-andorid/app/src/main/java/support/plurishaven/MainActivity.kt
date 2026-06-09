package support.plurishaven

import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

class MainActivity : ComponentActivity() {
	private var pendingExportText: String? = null
	private var importText by mutableStateOf<String?>(null)
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
		}.onSuccess { text ->
			importText = text
			fileStatus = null
		}.onFailure { error ->
			fileStatus = "Import failed: ${error.message ?: "unknown error"}"
		}
	}

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)

		setContent {
			PlurisHavenApp(
				fileStatus = fileStatus,
				importText = importText,
				onImport = {
					openImportFile.launch(
						arrayOf(
							"application/json",
							"text/*",
							"application/octet-stream"
						)
					)
				},
				onImportConsumed = {
					importText = null
				},
				onExport = { exportText ->
					pendingExportText = exportText
					createExportFile.launch("pluris-haven-export.json")
				}
			)
		}
	}
}
