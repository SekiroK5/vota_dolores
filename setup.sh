#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
flutter create --project-name vota_dolores_hidalgo .
rm -f test/widget_test.dart
flutter pub get
flutter test
