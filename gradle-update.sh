#!/bin/bash
# SPDX-FileCopyrightText: 2023 FC Stegerman <flx@obfusk.net>
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

gradle_wrapper="${1:-gradle/wrapper/gradle-wrapper.jar}"
gradle_wrapper_properties="${2:-gradle/wrapper/gradle-wrapper.properties}"
gradlew="${3:-./gradlew}"
outputs_file="${4:-}"

transparency_log=https://fdroid.gitlab.io/gradle-transparency-log/checksums.json
all_versions_url=https://services.gradle.org/versions/all
jq_filter='.[] | select(.current) | .version, .downloadUrl, .checksumUrl, .wrapperChecksumUrl'

read -r version download_url checksum_url wrapper_checksum_url < \
  <( curl -sL -- "$all_versions_url" | jq -r "$jq_filter" | tr '\n' ' ' ; echo )

checksum="$( curl -sL -- "$checksum_url" | cut -c-64 )"
wrapper_checksum="$( curl -sL -- "$wrapper_checksum_url" | cut -c-64 )"

show_info() {
  echo "version=$version"
  echo "download_url=$download_url"
  echo "checksum=$checksum"
  echo "wrapper_checksum=$wrapper_checksum"
}

get_properties_sum_and_url() {
  current_sum="$( grep -Po '(?<=^distributionSha256Sum=)(.*)' "$gradle_wrapper_properties" )"
  current_url="$( grep -Po '(?<=^distributionUrl=)(.*)' "$gradle_wrapper_properties" )"
}

check_transparency_log_checksum() {
  local what="$1" url="$2" sum="$3" filter='.[env.url][0].sha256'
  if [ "$( curl -sL -- "$transparency_log" | url="$url" jq -r "$filter" )" = "$sum" ]; then
    echo "transparency log $what checksum OK"
  else
    echo "transparency log $what checksum mismatch" >&2
    exit 1
  fi
}

check_transparency_log() {
  check_transparency_log_checksum download "$download_url" "$checksum"
  check_transparency_log_checksum wrapper "${wrapper_checksum_url%.sha256}" "$wrapper_checksum"
}

check_download() {
  if [ "$( curl -sL -- "$download_url" | sha256sum | cut -c-64 )" = "$checksum" ]; then
    echo 'download checksum OK'
  else
    echo 'download checksum mismatch' >&2
    exit 1
  fi
}

check_wrapper() {
  if [ "$( sha256sum "$gradle_wrapper" | cut -c-64 )" = "$wrapper_checksum" ]; then
    echo 'wrapper checksum OK'
  else
    echo 'wrapper checksum mismatch' >&2
    exit 1
  fi
}

check_properties_sum() {
  if [ "$current_sum" != "$checksum" ]; then
    echo 'gradle-wrapper.properties checksum mismatch' >&2
    exit 1
  fi
}

check_properties_url() {
  if [ "$current_url" != "${download_url//:/\\:}" ]; then
    echo 'gradle-wrapper.properties URL mismatch' >&2
    exit 1
  fi
}

check_properties_sum_and_url() {
  get_properties_sum_and_url
  check_properties_sum
  check_properties_url
}

check_url_unchanged() {
  get_properties_sum_and_url
  if [ "$current_url" = "${download_url//:/\\:}" ]; then
    echo 'download URL unchanged'
  else
    return 1
  fi
}

update_gradle_version() {
  echo "updating gradle version to $version..."
  "${gradlew}" wrapper --gradle-version "$version" --gradle-distribution-sha256-sum "$checksum"
}

update_wrapper() {
  echo 'updating wrapper...'
  "${gradlew}" wrapper
}

if [ ! -f "$gradle_wrapper" ]; then
  echo "no such file: $gradle_wrapper" >&2
  exit 1
fi
if [ ! -f "$gradle_wrapper_properties" ]; then
  echo "no such file: $gradle_wrapper_properties" >&2
  exit 1
fi
if [ ! -x "$gradlew" ]; then
  echo "no such executable: $gradlew" >&2
  exit 1
fi

show_info

if [ -n "$outputs_file" ]; then
  show_info >> "$outputs_file"
fi

if check_url_unchanged; then
  check_properties_sum
  check_wrapper
  check_transparency_log
  check_download
else
  check_transparency_log
  check_download
  update_gradle_version
  check_properties_sum_and_url
  update_wrapper
  check_wrapper
fi

echo done.
