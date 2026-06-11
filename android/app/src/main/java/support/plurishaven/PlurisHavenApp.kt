package support.plurishaven

import androidx.compose.runtime.Composable
import support.plurishaven.core.storage.HavenState
import support.plurishaven.feature.home.HomeScreen
import support.plurishaven.ui.theme.PlurisHavenTheme

@Composable
fun PlurisHavenApp(
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
	onAddLog: (String) -> Unit,
	onExport: () -> Unit
) {
	PlurisHavenTheme {
		HomeScreen(
			state = state,
			fileStatus = fileStatus,
			onImport = onImport,
			onSetFront = onSetFront,
			onToggleMemberFront = onToggleMemberFront,
			onClearFront = onClearFront,
			onAddMember = onAddMember,
			onUpdateMemberField = onUpdateMemberField,
			onToggleMemberArchived = onToggleMemberArchived,
			onAddFolder = onAddFolder,
			onAddCustomField = onAddCustomField,
			onAddNote = onAddNote,
			onAddLog = onAddLog,
			onExport = onExport
		)
	}
}
