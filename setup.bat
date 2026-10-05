@echo off
cd /d "%~dp0"
call flutter create --project-name vota_dolores_hidalgo .
if exist test\widget_test.dart del test\widget_test.dart
call flutter pub get
call flutter test
