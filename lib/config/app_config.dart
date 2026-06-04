// Google Maps / Places API key.
//
// Pass at build / run time:
//   flutter run  --dart-define=GOOGLE_MAPS_API_KEY=<your_key>
//   flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=<your_key>
//
// VS Code: add to .vscode/launch.json → "args": ["--dart-define=GOOGLE_MAPS_API_KEY=<key>"]
// Android Studio: Run → Edit Configurations → Additional run args
class AppConfig {
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
}
