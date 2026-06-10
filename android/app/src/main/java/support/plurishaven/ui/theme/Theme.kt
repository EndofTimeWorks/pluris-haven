package support.plurishaven.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
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
	primary = Color(0xFFC7D2FE),
	onPrimary = Color(0xFF1E1B4B),
	primaryContainer = Color(0xFF3730A3),
	onPrimaryContainer = Color(0xFFE0E7FF),
	secondary = Color(0xFF99F6E4),
	onSecondary = Color(0xFF042F2E),
	secondaryContainer = Color(0xFF115E59),
	onSecondaryContainer = Color(0xFFCCFBF1),
	tertiary = Color(0xFFFCD34D),
	tertiaryContainer = Color(0xFF92400E),
	onTertiaryContainer = Color(0xFFFFFBEB),
	background = Color(0xFF0F172A),
	onBackground = Color(0xFFE5E7EB),
	surface = Color(0xFF111827),
	onSurface = Color(0xFFE5E7EB),
	surfaceVariant = Color(0xFF1E293B),
	onSurfaceVariant = Color(0xFFCBD5E1)
)

@Composable
fun PlurisHavenTheme(
	darkTheme: Boolean = isSystemInDarkTheme(),
	content: @Composable () -> Unit
) {
	MaterialTheme(
		colorScheme = if (darkTheme) DarkColors else LightColors,
		content = content
	)
}
