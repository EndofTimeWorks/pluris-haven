package support.plurishaven.feature.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import support.plurishaven.core.storage.HavenLog
import support.plurishaven.core.storage.HavenState
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
	state: HavenState,
	fileStatus: String?,
	onImport: () -> Unit,
	onSetFront: (String) -> Unit,
	onClearFront: () -> Unit,
	onAddLog: (String) -> Unit,
	onExport: () -> Unit,
	modifier: Modifier = Modifier
) {
	var frontInput by rememberSaveable { mutableStateOf("") }
	var logInput by rememberSaveable { mutableStateOf("") }

	Scaffold(
		modifier = modifier.fillMaxSize(),
		containerColor = MaterialTheme.colorScheme.background,
		topBar = {
			TopAppBar(
				title = {
					Column {
						Text(
							text = "Pluris Haven",
							maxLines = 1,
							overflow = TextOverflow.Ellipsis
						)
						Text(
							text = "local",
							style = MaterialTheme.typography.labelMedium,
							color = MaterialTheme.colorScheme.onSurfaceVariant
						)
					}
				},
				colors = TopAppBarDefaults.topAppBarColors(
					containerColor = MaterialTheme.colorScheme.surface,
					titleContentColor = MaterialTheme.colorScheme.onSurface
				)
			)
		}
	) { innerPadding ->
		Column(
			modifier = Modifier
				.padding(innerPadding)
				.verticalScroll(rememberScrollState())
				.padding(16.dp),
			verticalArrangement = Arrangement.spacedBy(14.dp)
		) {
			StatusRow(fileStatus = fileStatus)

			FrontPanel(
				currentFront = state.currentFront,
				frontInput = frontInput,
				onFrontInputChange = { frontInput = it },
				onSetFront = {
					onSetFront(frontInput)
					frontInput = ""
				},
				onClearFront = onClearFront
			)

			LogPanel(
				logInput = logInput,
				onLogInputChange = { logInput = it },
				onAddLog = {
					onAddLog(logInput)
					logInput = ""
				}
			)

			StoragePanel(
				logCount = state.logs.size,
				onExport = onExport,
				onImport = onImport
			)

			RecentLogsPanel(logs = state.logs)

			OnlinePanel()
		}
	}
}

@Composable
private fun StatusRow(fileStatus: String?) {
	Row(
		modifier = Modifier.fillMaxWidth(),
		horizontalArrangement = Arrangement.spacedBy(8.dp)
	) {
		AssistChip(
			onClick = {},
			label = { Text("Offline") }
		)
		AssistChip(
			onClick = {},
			label = { Text(fileStatus ?: "Saved on device") }
		)
	}
}

@Composable
private fun FrontPanel(
	currentFront: String,
	frontInput: String,
	onFrontInputChange: (String) -> Unit,
	onSetFront: () -> Unit,
	onClearFront: () -> Unit
) {
	Panel {
		Text(
			text = "Current front",
			style = MaterialTheme.typography.labelLarge,
			color = MaterialTheme.colorScheme.onSurfaceVariant
		)
		Text(
			text = currentFront,
			style = MaterialTheme.typography.displaySmall,
			fontWeight = FontWeight.SemiBold,
			maxLines = 2,
			overflow = TextOverflow.Ellipsis
		)
		OutlinedTextField(
			value = frontInput,
			onValueChange = onFrontInputChange,
			modifier = Modifier.fillMaxWidth(),
			singleLine = true,
			label = { Text("Front label") }
		)
		Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
			Button(
				onClick = onSetFront,
				contentPadding = PaddingValues(horizontal = 18.dp, vertical = 10.dp)
			) {
				Text("Set front")
			}
			OutlinedButton(onClick = onClearFront) {
				Text("Clear")
			}
		}
	}
}

@Composable
private fun LogPanel(
	logInput: String,
	onLogInputChange: (String) -> Unit,
	onAddLog: () -> Unit
) {
	Panel {
		PanelTitle("Quick log")
		OutlinedTextField(
			value = logInput,
			onValueChange = onLogInputChange,
			modifier = Modifier.fillMaxWidth(),
			minLines = 3,
			label = { Text("Note") }
		)
		FilledTonalButton(onClick = onAddLog) {
			Text("Add log")
		}
	}
}

@Composable
private fun StoragePanel(
	logCount: Int,
	onExport: () -> Unit,
	onImport: () -> Unit
) {
	Panel {
		PanelTitle("Storage")
		Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
			FilterChip(
				selected = true,
				onClick = {},
				label = { Text("$logCount logs") }
			)
			FilterChip(
				selected = true,
				onClick = {},
				label = { Text("internal file") }
			)
		}
		Text(
			text = "State is saved in app-private storage. Export writes a portable JSON file.",
			style = MaterialTheme.typography.bodyMedium,
			color = MaterialTheme.colorScheme.onSurfaceVariant
		)
		Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
			Button(onClick = onExport) {
				Text("Export")
			}
			OutlinedButton(onClick = onImport) {
				Text("Import")
			}
		}
	}
}

@Composable
private fun RecentLogsPanel(logs: List<HavenLog>) {
	Panel {
		PanelTitle("Recent logs")
		logs.take(12).forEachIndexed { index, log ->
			if (index > 0) {
				HorizontalDivider()
			}
			LogRow(log = log)
		}
	}
}

@Composable
private fun LogRow(log: HavenLog) {
	Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
		Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
			Text(
				text = log.kind,
				style = MaterialTheme.typography.labelLarge,
				color = MaterialTheme.colorScheme.primary
			)
			Text(
				text = formatLogTime(log.createdAtEpochMillis),
				style = MaterialTheme.typography.labelMedium,
				color = MaterialTheme.colorScheme.onSurfaceVariant
			)
		}
		Text(
			text = log.text,
			style = MaterialTheme.typography.bodyLarge
		)
	}
}

@Composable
private fun OnlinePanel() {
	Panel {
		PanelTitle("Online")
		Text("Off by default.")
		Text(
			text = "Friends, sync, PluralKit, and chat bridges need a data notice before setup.",
			color = MaterialTheme.colorScheme.onSurfaceVariant
		)
	}
}

@Composable
private fun Panel(
	content: @Composable ColumnScope.() -> Unit
) {
	ElevatedCard(
		colors = CardDefaults.elevatedCardColors(
			containerColor = MaterialTheme.colorScheme.surface
		),
		elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp),
		shape = MaterialTheme.shapes.large
	) {
		Column(
			modifier = Modifier
				.fillMaxWidth()
				.padding(16.dp),
			verticalArrangement = Arrangement.spacedBy(12.dp)
		) {
			content()
		}
	}
}

@Composable
private fun PanelTitle(text: String) {
	Text(
		text = text,
		style = MaterialTheme.typography.titleMedium,
		fontWeight = FontWeight.SemiBold
	)
}

private fun formatLogTime(epochMillis: Long): String {
	val formatter = DateTimeFormatter.ofPattern("MMM d, HH:mm")
	return Instant
		.ofEpochMilli(epochMillis)
		.atZone(ZoneId.systemDefault())
		.format(formatter)
}
