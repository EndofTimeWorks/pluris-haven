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
	onClearFront: () -> Unit,
	onAddLog: (String) -> Unit,
	onExport: () -> Unit
) {
	PlurisHavenTheme {
		HomeScreen(
			state = state,
			fileStatus = fileStatus,
			onImport = onImport,
			onSetFront = onSetFront,
			onClearFront = onClearFront,
			onAddLog = onAddLog,
			onExport = onExport
		)
	}
}
