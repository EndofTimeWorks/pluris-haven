package support.plurishaven.feature.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import support.plurishaven.core.storage.HavenLog
import support.plurishaven.core.storage.HavenMember
import support.plurishaven.core.storage.HavenState
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private enum class HomeTab(
	val label: String,
	val mark: String
) {
	Front("Front", "F"),
	Members("Members", "M"),
	Logs("Logs", "L"),
	Data("Data", "D")
}

private val MemberColors = listOf(
	"#4F46E5",
	"#0F766E",
	"#B45309",
	"#DB2777",
	"#2563EB",
	"#7C3AED"
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
	state: HavenState,
	fileStatus: String?,
	onImport: () -> Unit,
	onSetFront: (String) -> Unit,
	onToggleMemberFront: (String) -> Unit,
	onClearFront: () -> Unit,
	onAddMember: (String, String, String) -> Unit,
	onAddLog: (String) -> Unit,
	onExport: () -> Unit,
	modifier: Modifier = Modifier
) {
	var selectedTab by rememberSaveable { mutableStateOf(HomeTab.Front) }

	Scaffold(
		modifier = modifier.fillMaxSize(),
		containerColor = MaterialTheme.colorScheme.background,
		topBar = {
			TopAppBar(
				title = {
					Column {
						Text("Pluris Haven")
						Text(
							text = fileStatus ?: "saved on device",
							style = MaterialTheme.typography.labelMedium,
							color = MaterialTheme.colorScheme.onSurfaceVariant
						)
					}
				},
				colors = TopAppBarDefaults.topAppBarColors(
					containerColor = MaterialTheme.colorScheme.surface
				)
			)
		},
		bottomBar = {
			NavigationBar {
				HomeTab.entries.forEach { tab ->
					NavigationBarItem(
						selected = selectedTab == tab,
						onClick = { selectedTab = tab },
						icon = { Text(tab.mark, fontWeight = FontWeight.Bold) },
						label = { Text(tab.label) }
					)
				}
			}
		}
	) { innerPadding ->
		when (selectedTab) {
			HomeTab.Front -> FrontTab(
				state = state,
				onSetFront = onSetFront,
				onToggleMemberFront = onToggleMemberFront,
				onClearFront = onClearFront,
				contentPadding = innerPadding
			)

			HomeTab.Members -> MembersTab(
				state = state,
				onAddMember = onAddMember,
				onToggleMemberFront = onToggleMemberFront,
				contentPadding = innerPadding
			)

			HomeTab.Logs -> LogsTab(
				logs = state.logs,
				onAddLog = onAddLog,
				contentPadding = innerPadding
			)

			HomeTab.Data -> DataTab(
				state = state,
				onExport = onExport,
				onImport = onImport,
				contentPadding = innerPadding
			)
		}
	}
}

@Composable
private fun FrontTab(
	state: HavenState,
	onSetFront: (String) -> Unit,
	onToggleMemberFront: (String) -> Unit,
	onClearFront: () -> Unit,
	contentPadding: PaddingValues
) {
	var frontInput by rememberSaveable { mutableStateOf("") }

	LazyColumn(
		modifier = Modifier
			.fillMaxSize()
			.padding(contentPadding),
		contentPadding = PaddingValues(16.dp),
		verticalArrangement = Arrangement.spacedBy(14.dp)
	) {
		item {
			CurrentFrontCard(
				currentFront = state.currentFrontLabel,
				activeCount = state.currentFrontMemberIds.size
			)
		}

		item {
			Panel {
				PanelTitle("Quick switch")
				if (state.members.isEmpty()) {
					Text(
						text = "Add members first, then front from here.",
						color = MaterialTheme.colorScheme.onSurfaceVariant
					)
				} else {
					state.members.forEach { member ->
						MemberRow(
							member = member,
							active = member.id in state.currentFrontMemberIds,
							onClick = { onToggleMemberFront(member.id) }
						)
					}
				}
			}
		}

		item {
			Panel {
				PanelTitle("Custom front")
				OutlinedTextField(
					value = frontInput,
					onValueChange = { frontInput = it },
					modifier = Modifier.fillMaxWidth(),
					singleLine = true,
					label = { Text("Label") }
				)
				Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
					Button(
						onClick = {
							onSetFront(frontInput)
							frontInput = ""
						}
					) {
						Text("Set")
					}
					OutlinedButton(onClick = onClearFront) {
						Text("Clear")
					}
				}
			}
		}
	}
}

@Composable
private fun CurrentFrontCard(
	currentFront: String,
	activeCount: Int
) {
	ElevatedCard(
		colors = CardDefaults.elevatedCardColors(
			containerColor = MaterialTheme.colorScheme.primaryContainer,
			contentColor = MaterialTheme.colorScheme.onPrimaryContainer
		),
		elevation = CardDefaults.elevatedCardElevation(defaultElevation = 3.dp),
		shape = MaterialTheme.shapes.extraLarge
	) {
		Column(
			modifier = Modifier
				.fillMaxWidth()
				.padding(20.dp),
			verticalArrangement = Arrangement.spacedBy(12.dp)
		) {
			Text(
				text = "Current front",
				style = MaterialTheme.typography.labelLarge
			)
			Text(
				text = currentFront,
				style = MaterialTheme.typography.displaySmall,
				fontWeight = FontWeight.Bold,
				maxLines = 3,
				overflow = TextOverflow.Ellipsis
			)
			AssistChip(
				onClick = {},
				label = {
					Text(if (activeCount == 0) "custom / none" else "$activeCount active")
				}
			)
		}
	}
}

@Composable
private fun MembersTab(
	state: HavenState,
	onAddMember: (String, String, String) -> Unit,
	onToggleMemberFront: (String) -> Unit,
	contentPadding: PaddingValues
) {
	var name by rememberSaveable { mutableStateOf("") }
	var pronouns by rememberSaveable { mutableStateOf("") }
	var colorHex by rememberSaveable { mutableStateOf(MemberColors.first()) }

	LazyColumn(
		modifier = Modifier
			.fillMaxSize()
			.padding(contentPadding),
		contentPadding = PaddingValues(16.dp),
		verticalArrangement = Arrangement.spacedBy(14.dp)
	) {
		item {
			Panel {
				PanelTitle("Add member")
				OutlinedTextField(
					value = name,
					onValueChange = { name = it },
					modifier = Modifier.fillMaxWidth(),
					singleLine = true,
					label = { Text("Name") }
				)
				OutlinedTextField(
					value = pronouns,
					onValueChange = { pronouns = it },
					modifier = Modifier.fillMaxWidth(),
					singleLine = true,
					label = { Text("Pronouns") }
				)
				Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
					MemberColors.forEach { option ->
						FilterChip(
							selected = colorHex == option,
							onClick = { colorHex = option },
							label = { ColorDot(option) }
						)
					}
				}
				Button(
					onClick = {
						onAddMember(name, pronouns, colorHex)
						name = ""
						pronouns = ""
					}
				) {
					Text("Add")
				}
			}
		}

		if (state.members.isEmpty()) {
			item {
				Panel {
					PanelTitle("Members")
					Text(
						text = "No members yet.",
						color = MaterialTheme.colorScheme.onSurfaceVariant
					)
				}
			}
		} else {
			items(state.members, key = { it.id }) { member ->
				MemberCard(
					member = member,
					active = member.id in state.currentFrontMemberIds,
					onToggleFront = { onToggleMemberFront(member.id) }
				)
			}
		}
	}
}

@Composable
private fun MemberCard(
	member: HavenMember,
	active: Boolean,
	onToggleFront: () -> Unit
) {
	Panel {
		MemberHeader(member = member, active = active)
		Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
			Button(onClick = onToggleFront) {
				Text(if (active) "Remove from front" else "Set front")
			}
		}
	}
}

@Composable
private fun MemberRow(
	member: HavenMember,
	active: Boolean,
	onClick: () -> Unit
) {
	Row(
		modifier = Modifier.fillMaxWidth(),
		verticalAlignment = Alignment.CenterVertically,
		horizontalArrangement = Arrangement.SpaceBetween
	) {
		MemberHeader(
			member = member,
			active = active,
			modifier = Modifier.weight(1f)
		)
		TextButton(onClick = onClick) {
			Text(if (active) "off" else "front")
		}
	}
}

@Composable
private fun MemberHeader(
	member: HavenMember,
	active: Boolean,
	modifier: Modifier = Modifier
) {
	Row(
		modifier = modifier,
		verticalAlignment = Alignment.CenterVertically,
		horizontalArrangement = Arrangement.spacedBy(12.dp)
	) {
		ColorDot(member.colorHex, size = 18)
		Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
			Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
				Text(
					text = member.name,
					style = MaterialTheme.typography.titleMedium,
					fontWeight = FontWeight.SemiBold
				)
				if (active) {
					Text(
						text = "front",
						style = MaterialTheme.typography.labelMedium,
						color = MaterialTheme.colorScheme.primary
					)
				}
			}
			if (member.pronouns.isNotBlank()) {
				Text(
					text = member.pronouns,
					style = MaterialTheme.typography.bodyMedium,
					color = MaterialTheme.colorScheme.onSurfaceVariant
				)
			}
		}
	}
}

@Composable
private fun LogsTab(
	logs: List<HavenLog>,
	onAddLog: (String) -> Unit,
	contentPadding: PaddingValues
) {
	var logInput by rememberSaveable { mutableStateOf("") }

	LazyColumn(
		modifier = Modifier
			.fillMaxSize()
			.padding(contentPadding),
		contentPadding = PaddingValues(16.dp),
		verticalArrangement = Arrangement.spacedBy(14.dp)
	) {
		item {
			Panel {
				PanelTitle("Quick log")
				OutlinedTextField(
					value = logInput,
					onValueChange = { logInput = it },
					modifier = Modifier.fillMaxWidth(),
					minLines = 3,
					label = { Text("Note") }
				)
				Button(
					onClick = {
						onAddLog(logInput)
						logInput = ""
					}
				) {
					Text("Add log")
				}
			}
		}

		items(logs.take(40)) { log ->
			LogCard(log = log)
		}
	}
}

@Composable
private fun LogCard(log: HavenLog) {
	Panel {
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
		Text(text = log.text)
	}
}

@Composable
private fun DataTab(
	state: HavenState,
	onExport: () -> Unit,
	onImport: () -> Unit,
	contentPadding: PaddingValues
) {
	LazyColumn(
		modifier = Modifier
			.fillMaxSize()
			.padding(contentPadding),
		contentPadding = PaddingValues(16.dp),
		verticalArrangement = Arrangement.spacedBy(14.dp)
	) {
		item {
			Panel {
				PanelTitle("Local data")
				Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
					AssistChip(onClick = {}, label = { Text("${state.members.size} members") })
					AssistChip(onClick = {}, label = { Text("${state.logs.size} logs") })
				}
				Text(
					text = "Saved in app-private storage. Export is plain JSON for now.",
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

		item {
			Panel {
				PanelTitle("Online")
				Text("Off by default.")
				Text(
					text = "Friends, sync, PluralKit, and chat bridges need a data notice before setup.",
					color = MaterialTheme.colorScheme.onSurfaceVariant
				)
			}
		}
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

@Composable
private fun ColorDot(
	colorHex: String,
	size: Int = 16
) {
	Box(
		modifier = Modifier
			.size(size.dp)
			.clip(CircleShape)
			.background(parseColor(colorHex))
	)
}

private fun parseColor(colorHex: String): Color {
	return runCatching {
		Color(android.graphics.Color.parseColor(colorHex))
	}.getOrDefault(Color(0xFF4F46E5))
}

private fun formatLogTime(epochMillis: Long): String {
	val formatter = DateTimeFormatter.ofPattern("MMM d, HH:mm")
	return Instant
		.ofEpochMilli(epochMillis)
		.atZone(ZoneId.systemDefault())
		.format(formatter)
}
