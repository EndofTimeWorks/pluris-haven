package support.plurishaven.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightColors = lightColorScheme(
	primary = Color(0xFF4F46E5),
	onPrimary = Color(0xFFFFFFFF),
	primaryContainer = Color(0xFFE0E7FF),
	onPrimaryContainer = Color(0xFF1E1B4B),
	secondary = Color(0xFF0F766E),
	onSecondary = Color(0xFFFFFFFF),
	secondaryContainer = Color(0xFFCCFBF1),
	onSecondaryContainer = Color(0xFF042F2E),
	tertiary = Color(0xFFB45309),
	tertiaryContainer = Color(0xFFFDE68A),
	onTertiaryContainer = Color(0xFF451A03),
	background = Color(0xFFF6F7FB),
	onBackground = Color(0xFF111827),
	surface = Color(0xFFFFFFFF),
	onSurface = Color(0xFF111827),
	surfaceVariant = Color(0xFFE5E7EB),
	onSurfaceVariant = Color(0xFF4B5563),
	outline = Color(0xFFCBD5E1)
)

private val DarkColors = darkColorScheme(
	primary = Color(0xFF7D6AF2),
	onPrimary = Color(0xFFFFFFFF),
	primaryContainer = Color(0xFF35324A),
	onPrimaryContainer = Color(0xFFE7E2FF),
	secondary = Color(0xFFE4BE63),
	onSecondary = Color(0xFF261D07),
	secondaryContainer = Color(0xFF4A3A18),
	onSecondaryContainer = Color(0xFFFFE7A5),
	tertiary = Color(0xFF8ED8C6),
	tertiaryContainer = Color(0xFF1D4B45),
	onTertiaryContainer = Color(0xFFC6FFF1),
	background = Color(0xFF191B24),
	onBackground = Color(0xFFE9E6EF),
	surface = Color(0xFF22242F),
	onSurface = Color(0xFFE9E6EF),
	surfaceVariant = Color(0xFF292C38),
	onSurfaceVariant = Color(0xFFC7C3D0),
	outline = Color(0xFF343847)
)

@Composable
fun PlurisHavenTheme(
	darkTheme: Boolean = true,
	content: @Composable () -> Unit
) {
	MaterialTheme(
		colorScheme = if (darkTheme) DarkColors else LightColors,
		content = content
	)
}
