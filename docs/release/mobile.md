# Mobile Release Process

Mobile CI runs on pushes and pull requests that touch `mobile/**`.
For debug builds, use the APK artifact from the `Mobile CI` workflow. That is
the easiest path during early development because it needs no version tag and
does not create a permanent GitHub Release.

The release workflow builds Android APKs and publishes a GitHub Release.
Normal pushes should use CI artifacts. GitHub Releases are reserved for explicit
version tags or manual workflow runs, so `main` does not fill up with throwaway
releases during early development.

## Debug Builds

Push to `main`, then open the finished `Mobile CI` workflow run and download the
`pluris-haven-debug-apk` artifact. Use this for emulator/device testing between
real releases.

## Version Tags

Use tags in this format:

```sh
git tag mobile-v0.1.0-dev.1+1
git push origin mobile-v0.1.0-dev.1+1
```

- `0.1.0-dev.1` becomes the GitHub Release version.
- `0.1.0` becomes Flutter `--build-name`.
- `1` becomes Flutter `--build-number`.
- If the tag omits `+1`, the workflow uses the GitHub run number.
- `0.x` and `-dev` / `-alpha` / `-rc` versions are published as GitHub
  prereleases.

Examples:

```sh
mobile-v0.1.0-dev.1+1
mobile-v0.1.0-alpha.1+2
mobile-v0.1.0+3
```

Do not use `1.0.0` tags until the mobile app is actually release-ready.

## Manual Releases

The `Mobile Release` workflow can also be run manually from GitHub Actions with:

- `version`: SemVer version such as `0.1.0-dev.1`
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
