plugins {
	id("com.android.application")
	id("org.jetbrains.kotlin.plugin.compose")
}

android {
	namespace = "support.plurishaven"

	compileSdk {
		version = release(36)
	}

	defaultConfig {
		applicationId = "support.plurishaven"

		minSdk {
			version = release(26)
		}

		targetSdk {
			version = release(36)
		}

		versionCode = 1
		versionName = "0.1.0"
	}

	buildFeatures {
		compose = true
	}
}

dependencies {
	val composeBom = platform("androidx.compose:compose-bom:2026.05.01")

	implementation(composeBom)
	androidTestImplementation(composeBom)

	implementation("androidx.activity:activity-compose:1.13.0")
	implementation("androidx.compose.foundation:foundation")
	implementation("androidx.compose.material3:material3")
	implementation("androidx.compose.ui:ui")
	implementation("androidx.compose.ui:ui-tooling-preview")

	debugImplementation("androidx.compose.ui:ui-tooling")
}
