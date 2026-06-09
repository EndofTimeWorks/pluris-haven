package support.plurishaven

import androidx.compose.runtime.Composable
import support.plurishaven.feature.home.HomeScreen
import support.plurishaven.ui.theme.PlurisHavenTheme

@Composable
fun PlurisHavenApp(
	fileStatus: String?,
	importText: String?,
	onImport: () -> Unit,
	onImportConsumed: () -> Unit,
	onExport: (String) -> Unit
) {
	PlurisHavenTheme {
		HomeScreen(
			fileStatus = fileStatus,
			importText = importText,
			onImport = onImport,
			onImportConsumed = onImportConsumed,
			onExport = onExport
		)
	}
}
