# oss-surveys-customer

Consumer display application for displaying surveys.

### To develop
1. Install packages by running `flutter pub get`
2. Verify `oss-surveys-api-spec` submodule directory is populated
  - if not, `git submodule init` and `git submodule update`
3. `flutter pub run build_runner build --delete-conflicting-outputs`

### Working with database
After editing database or entity/table classes, code generation needs to be ran with `flutter pub run build_runner build`   
Another option is to have `flutter pub run build_runner watch` running in the background.

#### Defining new table
1. Create entity_name.dart and define corresponding class [reference](https://drift.simonbinder.eu/docs/getting-started/#declaring-tables)
2. Define migrations in tables.drift
3. Add new migration to database.dart [reference](https://drift.simonbinder.eu/docs/advanced-features/migrations/#basics)
4. Run code generation described earlier.

#### Building
Build with `flutter build apk --split-per-abi`

#### Localizations
1. Add new localization to `lib/app_en|fi.yaml`
2. Run `flutter gen-l10n` to generate localization files

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
 
 
