#!/bin/sh -l
gradle_wrapper="$1"
gradle_wrapper_properties="$2"
gradlew="$3"
exec /gradle-update.sh "$gradle_wrapper" "$gradle_wrapper_properties" "$gradlew" "$GITHUB_OUTPUT"
