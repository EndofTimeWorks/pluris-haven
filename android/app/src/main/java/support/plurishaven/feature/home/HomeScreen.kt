package support.plurishaven.feature.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import org.json.JSONArray
import org.json.JSONObject

private data class LocalLog(
	val kind: String,
	val text: String
)

@Composable
fun HomeScreen(
	fileStatus: String?,
	importText: String?,
	onImport: () -> Unit,
	onImportConsumed: () -> Unit,
	onExport: (String) -> Unit,
	modifier: Modifier = Modifier
) {
	var currentFront = rememberSaveable { mutableStateOf("None") }
	var frontInput = rememberSaveable { mutableStateOf("") }
	var logInput = rememberSaveable { mutableStateOf("") }
	var screenStatus = rememberSaveable { mutableStateOf<String?>(null) }
	val logs = remember {
		mutableStateListOf(
			LocalLog("front", "No current front"),
			LocalLog("note", "Local data only")
		)
	}

	LaunchedEffect(importText) {
		val text = importText ?: return@LaunchedEffect
		runCatching {
			val json = JSONObject(text)
			currentFront.value = json.optString("currentFront", "None").ifBlank { "None" }
			logs.clear()

			val importedLogs = json.optJSONArray("logs") ?: JSONArray()
			for (index in 0 until importedLogs.length()) {
				val item = importedLogs.optJSONObject(index) ?: continue
				logs += LocalLog(
					kind = item.optString("kind", "note").ifBlank { "note" },
					text = item.optString("text", "").ifBlank { "(empty)" }
				)
			}

			if (logs.isEmpty()) {
				logs += LocalLog("note", "Imported empty log")
			}
		}.onSuccess {
			screenStatus.value = "Import loaded"
		}.onFailure { error ->
			screenStatus.value = "Import could not be read: ${error.message ?: "bad file"}"
		}
		onImportConsumed()
	}

	Surface(
		modifier = modifier.fillMaxSize(),
		color = MaterialTheme.colorScheme.background
	) {
		Column(
			modifier = Modifier
				.verticalScroll(rememberScrollState())
				.padding(16.dp),
			verticalArrangement = Arrangement.spacedBy(12.dp)
		) {
			AppHeader()

			StatusLine(fileStatus = fileStatus, screenStatus = screenStatus.value)

			Section(title = "Front") {
				Text(
					text = currentFront.value,
					style = MaterialTheme.typography.headlineSmall,
					fontWeight = FontWeight.SemiBold
				)
				OutlinedTextField(
					value = frontInput.value,
					onValueChange = { frontInput.value = it },
					modifier = Modifier.fillMaxWidth(),
					singleLine = true,
					label = { Text("Front label") }
				)
				Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
					Button(
						onClick = {
							val next = frontInput.value.trim().ifBlank { "Unknown" }
							currentFront.value = next
							logs.add(0, LocalLog("front", "Set front: $next"))
							frontInput.value = ""
							screenStatus.value = "Front updated"
						}
					) {
						Text("Set")
					}
					OutlinedButton(
						onClick = {
							currentFront.value = "None"
							logs.add(0, LocalLog("front", "Cleared front"))
							screenStatus.value = "Front cleared"
						}
					) {
						Text("Clear")
					}
				}
			}

			Section(title = "Log") {
				OutlinedTextField(
					value = logInput.value,
					onValueChange = { logInput.value = it },
					modifier = Modifier.fillMaxWidth(),
					minLines = 2,
					label = { Text("Note") }
				)
				Button(
					onClick = {
						val text = logInput.value.trim()
						if (text.isNotEmpty()) {
							logs.add(0, LocalLog("note", text))
							logInput.value = ""
							screenStatus.value = "Log added"
						}
					}
				) {
					Text("Add")
				}
			}

			Section(title = "Import / export") {
				Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
					Button(onClick = { onExport(buildExport(currentFront.value, logs)) }) {
						Text("Export")
					}
					OutlinedButton(onClick = onImport) {
						Text("Import")
					}
				}
				Text(
					text = "Exports include this screen's front and logs. Service tokens are not included.",
					style = MaterialTheme.typography.bodySmall,
					color = MaterialTheme.colorScheme.onSurfaceVariant
				)
			}

			Section(title = "Recent logs") {
				logs.take(10).forEachIndexed { index, log ->
					if (index > 0) {
						HorizontalDivider()
					}
					Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
						Text(
							text = log.kind,
							style = MaterialTheme.typography.labelMedium,
							color = MaterialTheme.colorScheme.onSurfaceVariant
						)
						Text(text = log.text)
					}
				}
			}

			Section(title = "Online") {
				Text("Off by default.")
				Text("Friends, sync, PK, and chat bridges need a clear data notice before setup.")
			}
		}
	}
}

@Composable
private fun AppHeader() {
	Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
		Text(
			text = "Pluris Haven",
			style = MaterialTheme.typography.headlineMedium,
			fontWeight = FontWeight.SemiBold
		)
		Text(
			text = "Local first. Android first.",
			style = MaterialTheme.typography.bodyMedium,
			color = MaterialTheme.colorScheme.onSurfaceVariant
		)
	}
}

@Composable
private fun StatusLine(fileStatus: String?, screenStatus: String?) {
	val text = fileStatus ?: screenStatus ?: "Ready"
	Text(
		text = text,
		style = MaterialTheme.typography.bodySmall,
		color = MaterialTheme.colorScheme.onSurfaceVariant
	)
}

@Composable
private fun Section(
	title: String,
	content: @Composable ColumnScope.() -> Unit
) {
	Card(
		colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
		elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
	) {
		Column(
			modifier = Modifier
				.fillMaxWidth()
				.padding(14.dp),
			verticalArrangement = Arrangement.spacedBy(10.dp)
		) {
			Text(
				text = title,
				style = MaterialTheme.typography.titleMedium,
				fontWeight = FontWeight.SemiBold
			)
			content()
		}
	}
}

private fun buildExport(
	currentFront: String,
	logs: List<LocalLog>
): String {
	val jsonLogs = JSONArray()
	logs.forEach { log ->
		jsonLogs.put(
			JSONObject()
				.put("kind", log.kind)
				.put("text", log.text)
		)
	}

	return JSONObject()
		.put("format", "pluris-haven/basic")
		.put("version", 1)
		.put("currentFront", currentFront)
		.put("logs", jsonLogs)
		.toString(2)
}
