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
	onAddMember: (String, String, String) -> Unit,
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
			onAddLog = onAddLog,
			onExport = onExport
		)
	}
}
