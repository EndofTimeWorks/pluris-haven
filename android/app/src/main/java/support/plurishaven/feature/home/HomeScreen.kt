package support.plurishaven.feature.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
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
import support.plurishaven.core.storage.HavenCustomField
import support.plurishaven.core.storage.HavenFolder
import support.plurishaven.core.storage.HavenFrontEvent
import support.plurishaven.core.storage.HavenMember
import support.plurishaven.core.storage.HavenNote
import support.plurishaven.core.storage.HavenState
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private enum class HomeTab(
	val label: String,
	val mark: String
) {
	Front("Front", "F"),
	Members("Members", "M"),
	Groups("Groups", "G"),
	Notes("Notes", "N"),
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
	onAddMember: (String, String, String, String?, String, String, String) -> Unit,
	onUpdateMemberField: (String, String, String) -> Unit,
	onToggleMemberArchived: (String) -> Unit,
	onAddFolder: (String, String) -> Unit,
	onAddCustomField: (String) -> Unit,
	onAddNote: (String, String, String?, String) -> Unit,
	@Suppress("UNUSED_PARAMETER") onAddLog: (String) -> Unit,
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
				onUpdateMemberField = onUpdateMemberField,
				onToggleMemberArchived = onToggleMemberArchived,
				onAddCustomField = onAddCustomField,
				onToggleMemberFront = onToggleMemberFront,
				contentPadding = innerPadding
			)

			HomeTab.Groups -> GroupsTab(
				state = state,
				onAddFolder = onAddFolder,
				contentPadding = innerPadding
			)

			HomeTab.Notes -> NotesTab(
				state = state,
				onAddNote = onAddNote,
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
	val visibleMembers = state.members.filterNot { it.archived }

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
				activeCount = state.currentFrontMemberIds.size,
				startedAtEpochMillis = state.currentFrontStartedAtEpochMillis
			)
		}

		item {
			Panel {
				PanelTitle("Quick switch")
				if (visibleMembers.isEmpty()) {
					Text(
						text = "Add members first, then front from here.",
						color = MaterialTheme.colorScheme.onSurfaceVariant
					)
				} else {
					visibleMembers.forEach { member ->
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

		item {
			Panel {
				PanelTitle("Front history")
				if (state.frontHistory.isEmpty()) {
					Text(
						text = "No front history yet.",
						color = MaterialTheme.colorScheme.onSurfaceVariant
					)
				} else {
					state.frontHistory.take(8).forEach { event ->
						FrontHistoryRow(event = event)
					}
				}
			}
		}
	}
}

@Composable
private fun CurrentFrontCard(
	currentFront: String,
	activeCount: Int,
	startedAtEpochMillis: Long?
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
			if (startedAtEpochMillis != null) {
				Text(
					text = "Since ${formatLogTime(startedAtEpochMillis)}",
					style = MaterialTheme.typography.bodyMedium,
					color = MaterialTheme.colorScheme.onPrimaryContainer
				)
			}
		}
	}
}

@Composable
private fun MembersTab(
	state: HavenState,
	onAddMember: (String, String, String, String?, String, String, String) -> Unit,
	onUpdateMemberField: (String, String, String) -> Unit,
	onToggleMemberArchived: (String) -> Unit,
	onAddCustomField: (String) -> Unit,
	onToggleMemberFront: (String) -> Unit,
	contentPadding: PaddingValues
) {
	var name by rememberSaveable { mutableStateOf("") }
	var pronouns by rememberSaveable { mutableStateOf("") }
	var colorHex by rememberSaveable { mutableStateOf(MemberColors.first()) }
	var folderId by rememberSaveable { mutableStateOf<String?>(null) }
	var description by rememberSaveable { mutableStateOf("") }
	var avatarUrl by rememberSaveable { mutableStateOf("") }
	var pluralKitId by rememberSaveable { mutableStateOf("") }
	var customFieldName by rememberSaveable { mutableStateOf("") }

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
				OutlinedTextField(
					value = description,
					onValueChange = { description = it },
					modifier = Modifier.fillMaxWidth(),
					minLines = 2,
					label = { Text("Description") }
				)
				OutlinedTextField(
					value = avatarUrl,
					onValueChange = { avatarUrl = it },
					modifier = Modifier.fillMaxWidth(),
					singleLine = true,
					label = { Text("Avatar URL") }
				)
				OutlinedTextField(
					value = pluralKitId,
					onValueChange = { pluralKitId = it },
					modifier = Modifier.fillMaxWidth(),
					singleLine = true,
					label = { Text("PluralKit ID") }
				)
				Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
					Text(
						text = "Group",
						style = MaterialTheme.typography.labelLarge,
						color = MaterialTheme.colorScheme.onSurfaceVariant
					)
					LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
						item {
							FilterChip(
								selected = folderId == null,
								onClick = { folderId = null },
								label = { Text("None") }
							)
						}
						items(state.folders, key = { it.id }) { folder ->
							FilterChip(
								selected = folderId == folder.id,
								onClick = { folderId = folder.id },
								label = { Text(folderLabel(folder)) },
								leadingIcon = { ColorDot(folder.colorHex, size = 10) }
							)
						}
					}
				}
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
						onAddMember(
							name,
							pronouns,
							colorHex,
							folderId,
							description,
							avatarUrl,
							pluralKitId
						)
						name = ""
						pronouns = ""
						description = ""
						avatarUrl = ""
						pluralKitId = ""
					}
				) {
					Text("Add")
				}
			}
		}

		item {
			Panel {
				PanelTitle("Custom fields")
				OutlinedTextField(
					value = customFieldName,
					onValueChange = { customFieldName = it },
					modifier = Modifier.fillMaxWidth(),
					singleLine = true,
					label = { Text("Field name") }
				)
				Button(
					onClick = {
						onAddCustomField(customFieldName)
						customFieldName = ""
					}
				) {
					Text("Add field")
				}
				if (state.customFields.isNotEmpty()) {
					HorizontalDivider()
					state.customFields.sortedBy { it.order }.forEach { field ->
						Text(
							text = field.name,
							style = MaterialTheme.typography.bodyMedium,
							color = MaterialTheme.colorScheme.onSurfaceVariant
						)
					}
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
					folder = state.folders.firstOrNull { it.id == member.folderId },
					customFields = state.customFields.sortedBy { it.order },
					notes = state.notes.filter { it.memberId == member.id },
					active = member.id in state.currentFrontMemberIds,
					onToggleFront = { onToggleMemberFront(member.id) },
					onUpdateField = { fieldId, value ->
						onUpdateMemberField(member.id, fieldId, value)
					},
					onToggleArchived = { onToggleMemberArchived(member.id) }
				)
			}
		}
	}
}

@Composable
private fun FrontHistoryRow(event: HavenFrontEvent) {
	Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
		Row(
			modifier = Modifier.fillMaxWidth(),
			horizontalArrangement = Arrangement.SpaceBetween,
			verticalAlignment = Alignment.CenterVertically
		) {
			Text(
				text = event.label,
				style = MaterialTheme.typography.bodyLarge,
				fontWeight = FontWeight.Medium,
				modifier = Modifier.weight(1f),
				maxLines = 1,
				overflow = TextOverflow.Ellipsis
			)
			Text(
				text = eventDuration(event),
				style = MaterialTheme.typography.labelMedium,
				color = MaterialTheme.colorScheme.onSurfaceVariant
			)
		}
		Text(
			text = "${formatLogTime(event.startedAtEpochMillis)} - ${event.endedAtEpochMillis?.let(::formatLogTime) ?: "now"}",
			style = MaterialTheme.typography.bodySmall,
			color = MaterialTheme.colorScheme.onSurfaceVariant
		)
	}
}

@Composable
private fun MemberCard(
	member: HavenMember,
	folder: HavenFolder?,
	customFields: List<HavenCustomField>,
	notes: List<HavenNote>,
	active: Boolean,
	onToggleFront: () -> Unit,
	onUpdateField: (String, String) -> Unit,
	onToggleArchived: () -> Unit
) {
	Panel {
		MemberHeader(member = member, active = active)
		if (folder != null) {
			MetadataLine(
				colorHex = folder.colorHex,
				label = "Group",
				value = folderLabel(folder)
			)
		}
		if (member.description.isNotBlank()) {
			Text(
				text = member.description,
				color = MaterialTheme.colorScheme.onSurfaceVariant,
				maxLines = 4,
				overflow = TextOverflow.Ellipsis
			)
		}
		if (member.avatarUrl.isNotBlank()) {
			MetadataLine(label = "Avatar", value = member.avatarUrl)
		}
		if (member.pluralKitId.isNotBlank()) {
			MetadataLine(label = "PluralKit", value = member.pluralKitId)
		}
		if (member.archived) {
			Text(
				text = member.archivedReason.ifBlank { "Archived" },
				style = MaterialTheme.typography.labelLarge,
				color = MaterialTheme.colorScheme.error
			)
		}
		if (customFields.isNotEmpty()) {
			HorizontalDivider()
			customFields.forEach { field ->
				MemberCustomFieldRow(
					field = field,
					initial = member.customFields[field.id].orEmpty(),
					onSave = { value -> onUpdateField(field.id, value) }
				)
			}
		}
		if (notes.isNotEmpty()) {
			HorizontalDivider()
			notes.take(3).forEach { note ->
				NotePreview(note = note)
			}
		}
		Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
			Button(onClick = onToggleFront) {
				Text(if (active) "Remove from front" else "Set front")
			}
			OutlinedButton(onClick = onToggleArchived) {
				Text(if (member.archived) "Restore" else "Archive")
			}
		}
	}
}

@Composable
private fun MemberCustomFieldRow(
	field: HavenCustomField,
	initial: String,
	onSave: (String) -> Unit
) {
	var draft by rememberSaveable(field.id, initial) { mutableStateOf(initial) }

	Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
		OutlinedTextField(
			value = draft,
			onValueChange = { draft = it },
			modifier = Modifier.fillMaxWidth(),
			singleLine = true,
			label = { Text(field.name) }
		)
		TextButton(onClick = { onSave(draft) }) {
			Text("Save ${field.name}")
		}
	}
}

@Composable
private fun MetadataLine(
	label: String,
	value: String,
	colorHex: String? = null
) {
	Row(
		verticalAlignment = Alignment.CenterVertically,
		horizontalArrangement = Arrangement.spacedBy(8.dp)
	) {
		if (colorHex != null) {
			ColorDot(colorHex, size = 12)
		}
		Text(
			text = "$label:",
			style = MaterialTheme.typography.labelLarge,
			color = MaterialTheme.colorScheme.onSurfaceVariant
		)
		Text(
			text = value,
			style = MaterialTheme.typography.bodyMedium,
			color = MaterialTheme.colorScheme.onSurfaceVariant,
			maxLines = 1,
			overflow = TextOverflow.Ellipsis
		)
	}
}

@Composable
private fun GroupsTab(
	state: HavenState,
	onAddFolder: (String, String) -> Unit,
	contentPadding: PaddingValues
) {
	var name by rememberSaveable { mutableStateOf("") }
	var colorHex by rememberSaveable { mutableStateOf(MemberColors[1]) }

	LazyColumn(
		modifier = Modifier
			.fillMaxSize()
			.padding(contentPadding),
		contentPadding = PaddingValues(16.dp),
		verticalArrangement = Arrangement.spacedBy(14.dp)
	) {
		item {
			Panel {
				PanelTitle("Add group")
				OutlinedTextField(
					value = name,
					onValueChange = { name = it },
					modifier = Modifier.fillMaxWidth(),
					singleLine = true,
					label = { Text("Name") }
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
						onAddFolder(name, colorHex)
						name = ""
					}
				) {
					Text("Add")
				}
			}
		}

		if (state.folders.isEmpty()) {
			item {
				Panel {
					PanelTitle("Groups")
					Text(
						text = "No groups yet.",
						color = MaterialTheme.colorScheme.onSurfaceVariant
					)
				}
			}
		} else {
			items(state.folders, key = { it.id }) { folder ->
				GroupCard(
					folder = folder,
					members = state.members.filter { it.folderId == folder.id }
				)
			}
		}

		val ungroupedMembers = state.members.filter { it.folderId == null }
		if (ungroupedMembers.isNotEmpty()) {
			item {
				GroupCard(
					folder = HavenFolder(
						id = "ungrouped",
						name = "Ungrouped",
						colorHex = "#64748B",
						parentId = null,
						description = "",
						emoji = ""
					),
					members = ungroupedMembers
				)
			}
		}
	}
}

@Composable
private fun GroupCard(
	folder: HavenFolder,
	members: List<HavenMember>
) {
	Panel {
		Row(
			verticalAlignment = Alignment.CenterVertically,
			horizontalArrangement = Arrangement.spacedBy(10.dp)
		) {
			ColorDot(folder.colorHex, size = 16)
			Column {
				Text(
					text = folderLabel(folder),
					style = MaterialTheme.typography.titleMedium,
					fontWeight = FontWeight.SemiBold
				)
				Text(
					text = "${members.size} members",
					style = MaterialTheme.typography.bodyMedium,
					color = MaterialTheme.colorScheme.onSurfaceVariant
				)
			}
		}
		if (folder.description.isNotBlank()) {
			Text(
				text = folder.description,
				color = MaterialTheme.colorScheme.onSurfaceVariant
			)
		}
		if (members.isNotEmpty()) {
			HorizontalDivider()
			members.take(8).forEach { member ->
				MemberHeader(member = member, active = false)
			}
		}
	}
}

@Composable
private fun NotesTab(
	state: HavenState,
	onAddNote: (String, String, String?, String) -> Unit,
	contentPadding: PaddingValues
) {
	var title by rememberSaveable { mutableStateOf("") }
	var body by rememberSaveable { mutableStateOf("") }
	var colorHex by rememberSaveable { mutableStateOf(MemberColors[2]) }
	var memberId by rememberSaveable { mutableStateOf<String?>(null) }

	LazyColumn(
		modifier = Modifier
			.fillMaxSize()
			.padding(contentPadding),
		contentPadding = PaddingValues(16.dp),
		verticalArrangement = Arrangement.spacedBy(14.dp)
	) {
		item {
			Panel {
				PanelTitle("Add note")
				OutlinedTextField(
					value = title,
					onValueChange = { title = it },
					modifier = Modifier.fillMaxWidth(),
					singleLine = true,
					label = { Text("Title") }
				)
				OutlinedTextField(
					value = body,
					onValueChange = { body = it },
					modifier = Modifier.fillMaxWidth(),
					minLines = 4,
					label = { Text("Note") }
				)
				LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
					item {
						FilterChip(
							selected = memberId == null,
							onClick = { memberId = null },
							label = { Text("General") }
						)
					}
					items(state.members, key = { it.id }) { member ->
						FilterChip(
							selected = memberId == member.id,
							onClick = { memberId = member.id },
							label = { Text(member.name) },
							leadingIcon = { ColorDot(member.colorHex, size = 10) }
						)
					}
				}
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
						onAddNote(title, body, memberId, colorHex)
						title = ""
						body = ""
					}
				) {
					Text("Add")
				}
			}
		}

		if (state.notes.isEmpty()) {
			item {
				Panel {
					PanelTitle("Notes")
					Text(
						text = "No notes yet.",
						color = MaterialTheme.colorScheme.onSurfaceVariant
					)
				}
			}
		} else {
			items(state.notes, key = { it.id }) { note ->
				NoteCard(
					note = note,
					member = state.members.firstOrNull { it.id == note.memberId }
				)
			}
		}
	}
}

@Composable
private fun NoteCard(
	note: HavenNote,
	member: HavenMember?
) {
	Panel {
		Row(
			verticalAlignment = Alignment.CenterVertically,
			horizontalArrangement = Arrangement.spacedBy(8.dp)
		) {
			ColorDot(note.colorHex, size = 14)
			Text(
				text = note.title.ifBlank { "Untitled" },
				style = MaterialTheme.typography.titleMedium,
				fontWeight = FontWeight.SemiBold,
				modifier = Modifier.weight(1f),
				maxLines = 1,
				overflow = TextOverflow.Ellipsis
			)
		}
		Text(
			text = formatLogTime(note.createdAtEpochMillis),
			style = MaterialTheme.typography.labelMedium,
			color = MaterialTheme.colorScheme.onSurfaceVariant
		)
		if (member != null) {
			MetadataLine(colorHex = member.colorHex, label = "Member", value = member.name)
		}
		Text(
			text = note.body,
			color = MaterialTheme.colorScheme.onSurfaceVariant
		)
	}
}

@Composable
private fun NotePreview(note: HavenNote) {
	Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
		Row(
			verticalAlignment = Alignment.CenterVertically,
			horizontalArrangement = Arrangement.spacedBy(8.dp)
		) {
			ColorDot(note.colorHex, size = 10)
			Text(
				text = note.title.ifBlank { "Note" },
				style = MaterialTheme.typography.labelLarge,
				color = MaterialTheme.colorScheme.onSurfaceVariant
			)
		}
		Text(
			text = note.body,
			style = MaterialTheme.typography.bodySmall,
			color = MaterialTheme.colorScheme.onSurfaceVariant,
			maxLines = 2,
			overflow = TextOverflow.Ellipsis
		)
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
					fontWeight = FontWeight.SemiBold,
					maxLines = 1,
					overflow = TextOverflow.Ellipsis
				)
				if (active) {
					Text(
						text = "front",
						style = MaterialTheme.typography.labelMedium,
						color = MaterialTheme.colorScheme.primary
					)
				}
				if (member.archived) {
					Text(
						text = "archived",
						style = MaterialTheme.typography.labelMedium,
						color = MaterialTheme.colorScheme.error
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
				LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
					item { AssistChip(onClick = {}, label = { Text("${state.members.size} members") }) }
					item { AssistChip(onClick = {}, label = { Text("${state.folders.size} groups") }) }
					item { AssistChip(onClick = {}, label = { Text("${state.notes.size} notes") }) }
					item { AssistChip(onClick = {}, label = { Text("${state.customFields.size} fields") }) }
					item { AssistChip(onClick = {}, label = { Text("${state.frontHistory.size} fronts") }) }
				}
				Text(
					text = "Saved in app-private storage. Export includes familiar profiles, groups, custom fields, notes, front history, and local logs.",
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
				PanelTitle("Sync")
				Text("Off by default.")
				Text(
					text = "Accounts, friends, PluralKit, and bridges should sit behind an explicit sync setup later.",
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

private fun folderLabel(folder: HavenFolder): String {
	return listOf(folder.emoji, folder.name)
		.filter { it.isNotBlank() }
		.joinToString(" ")
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

private fun eventDuration(event: HavenFrontEvent): String {
	val endedAt = event.endedAtEpochMillis ?: System.currentTimeMillis()
	val duration = Duration.ofMillis((endedAt - event.startedAtEpochMillis).coerceAtLeast(0L))
	val hours = duration.toHours()
	val minutes = duration.toMinutes() % 60

	return when {
		hours > 0 -> "${hours}h ${minutes}m"
		minutes > 0 -> "${minutes}m"
		else -> "<1m"
	}
}
