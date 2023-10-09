# Gradle Version & Wrapper Update Docker action

This action updates the Gradle URL, SHA256 checksum, and wrapper for
your Android app.

It checks `https://services.gradle.org/versions/all` for the current
Gradle version and SHA256 checksums and then essentially runs these
commands to update Gradle, performing a few additional checks as well:

```sh
# update URL and SHA256 in gradle-wrapper.properties
$ ./gradlew wrapper --gradle-version $VERSION --gradle-distribution-sha256-sum $SHA256SUM
# update gradle-wrapper.jar, gradlew, and gradlew.bat
$ ./gradlew wrapper
```

## Inputs

### `gradle_wrapper`

The location of `gradle-wrapper.jar`.

Defaults to `gradle/wrapper/gradle-wrapper.jar`.

### `gradle_wrapper_properties`

The location of `gradle-wrapper.properties`.

Defaults to `gradle/wrapper/gradle-wrapper.properties`.

### `gradlew`

The location of the `gradlew` script to run.

Defaults to `./gradlew`.

## Outputs

### `version`

The gradle version.

### `download_url`

The download URL.

### `checksum`

The checksum for the download.

### `wrapper_checksum`

The checksum for the wrapper.

## Example usage

Put the following in `.github/workflows/gradle-update.yml`:

```yaml
jobs:
  gradle-update:
    runs-on: ubuntu-latest
    name: Gradle update
    steps:
    - name: Checkout repo
      uses: actions/checkout@v4
    - name: Gradle update
      id: gradle-update
      uses: obfusk/gradle-update-action@v1
    - name: Create pull request
      uses: peter-evans/create-pull-request@v5
      with:
        title: "Update Gradle to ${{ steps.gradle-update.outputs.version }}"
        commit-message: "Update Gradle to ${{ steps.gradle-update.outputs.version }}"
        branch-suffix: timestamp
on:
  schedule:
    - cron: '0 0 * * *'
```

## License

GNU General Public License v3.0 or later
