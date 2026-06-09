package support.plurishaven.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightColors = lightColorScheme(
	primary = Color(0xFF374151),
	onPrimary = Color(0xFFFFFFFF),
	primaryContainer = Color(0xFFE5E7EB),
	onPrimaryContainer = Color(0xFF111827),
	secondary = Color(0xFF4B5563),
	onSecondary = Color(0xFFFFFFFF),
	secondaryContainer = Color(0xFFF3F4F6),
	onSecondaryContainer = Color(0xFF111827),
	tertiary = Color(0xFF64748B),
	tertiaryContainer = Color(0xFFE2E8F0),
	onTertiaryContainer = Color(0xFF0F172A),
	background = Color(0xFFF8FAFC),
	onBackground = Color(0xFF111827),
	surface = Color(0xFFFFFFFF),
	onSurface = Color(0xFF111827),
	surfaceVariant = Color(0xFFF1F5F9),
	onSurfaceVariant = Color(0xFF475569)
)

private val DarkColors = darkColorScheme(
	primary = Color(0xFFD1D5DB),
	onPrimary = Color(0xFF111827),
	primaryContainer = Color(0xFF374151),
	onPrimaryContainer = Color(0xFFF9FAFB),
	secondary = Color(0xFFCBD5E1),
	onSecondary = Color(0xFF111827),
	secondaryContainer = Color(0xFF1F2937),
	onSecondaryContainer = Color(0xFFF9FAFB),
	tertiary = Color(0xFFCBD5E1),
	tertiaryContainer = Color(0xFF334155),
	onTertiaryContainer = Color(0xFFF8FAFC),
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
