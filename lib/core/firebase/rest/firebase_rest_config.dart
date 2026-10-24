import 'package:firebase_core/firebase_core.dart';

/// Endpoints of the Firebase REST APIs for one project, optionally pointed at the local emulators.
final class FirebaseRestConfig {
  const FirebaseRestConfig({
    required this.apiKey,
    required this.projectId,
    this.authEmulatorHost,
    this.firestoreEmulatorHost,
  });

  /// Uses the project's web app config (`flutterfire configure` with `web` included).
  factory FirebaseRestConfig.fromOptions(FirebaseOptions options) =>
      FirebaseRestConfig(apiKey: options.apiKey, projectId: options.projectId);

  final String apiKey;
  final String projectId;

  /// e.g. `127.0.0.1:9099`
  final String? authEmulatorHost;

  /// e.g. `127.0.0.1:8080`
  final String? firestoreEmulatorHost;

  Uri identityToolkit(String method) => Uri.parse(
    authEmulatorHost == null
        ? 'https://identitytoolkit.googleapis.com/v1/$method?key=$apiKey'
        : 'http://$authEmulatorHost/identitytoolkit.googleapis.com/v1/$method?key=$apiKey',
  );

  Uri get secureToken => Uri.parse(
    authEmulatorHost == null
        ? 'https://securetoken.googleapis.com/v1/token?key=$apiKey'
        : 'http://$authEmulatorHost/securetoken.googleapis.com/v1/token?key=$apiKey',
  );

  /// Resource name prefix of every document, e.g. `projects/p/databases/(default)/documents`.
  String get documentsRoot => 'projects/$projectId/databases/(default)/documents';

  /// [resource] is a full resource name, optionally followed by a custom method (`...:runQuery`).
  Uri firestore(String resource) => Uri.parse(
    firestoreEmulatorHost == null
        ? 'https://firestore.googleapis.com/v1/$resource'
        : 'http://$firestoreEmulatorHost/v1/$resource',
  );
}
