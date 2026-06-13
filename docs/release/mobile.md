# Mobile Release Process

Mobile CI runs on pushes and pull requests that touch `mobile/**`.

The release workflow builds Android APKs and publishes a GitHub Release.

## Version Tags

Use tags in this format:

```sh
git tag mobile-v0.1.0+1
git push origin mobile-v0.1.0+1
```

- `0.1.0` becomes Flutter `--build-name`.
- `1` becomes Flutter `--build-number`.
- If the tag omits `+1`, the workflow uses the GitHub run number.
- `0.x` versions are published as GitHub prereleases.

Examples:

```sh
mobile-v0.1.0+1
mobile-v0.1.1+2
mobile-v0.2.0+3
```

Do not use `1.0.0` tags until the mobile app is actually release-ready.

## Manual Releases

The `Mobile Release` workflow can also be run manually from GitHub Actions with:

- `version`: version name such as `0.1.0`
- `build_number`: integer build number
- `prerelease`: whether to mark the GitHub Release as prerelease

Manual runs publish to `mobile-v<version>+<build_number>`.

## Artifacts

The workflow uploads:

- universal release APK
- split per-ABI release APKs
- `SHA256SUMS.txt`

Release APKs are currently signed with the debug signing config because the app
does not have production signing keys yet. Before Play Store release, add
release signing through GitHub Actions secrets and update
`mobile/android/app/build.gradle.kts`.
