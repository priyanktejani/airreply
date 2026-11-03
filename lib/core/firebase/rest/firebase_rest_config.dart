import 'package:firebase_core/firebase_core.dart';

/// Endpoints of the Firebase REST APIs for one project, optionally pointed at the local emulators.
final class FirebaseRestConfig {
  const FirebaseRestConfig({
    required this.apiKey,
    required this.projectId,
    this.databaseUrl,
    this.authEmulatorHost,
    this.firestoreEmulatorHost,
    this.databaseEmulatorHost,
  });

  /// Uses the project's web app config (`flutterfire configure` with `web` included).
  factory FirebaseRestConfig.fromOptions(FirebaseOptions options) =>
      FirebaseRestConfig(apiKey: options.apiKey, projectId: options.projectId, databaseUrl: options.databaseURL);

  final String apiKey;
  final String projectId;

  /// The project's Realtime Database, e.g. `https://p-default-rtdb.asia-southeast1.firebasedatabase.app`; null when
  /// it has none (then nothing rings: see Doorbell).
  final String? databaseUrl;

  /// e.g. `127.0.0.1:9099`
  final String? authEmulatorHost;

  /// e.g. `127.0.0.1:8080`
  final String? firestoreEmulatorHost;

  /// e.g. `127.0.0.1:9000`
  final String? databaseEmulatorHost;

  /// Whether there is a Realtime Database to use.
  bool get hasDatabase => databaseEmulatorHost != null || (databaseUrl?.isNotEmpty ?? false);

  /// [path] in the Realtime Database, read and written as JSON with the ID token [auth].
  Uri database(String path, {required String auth}) => databaseEmulatorHost == null
      ? Uri.parse('$databaseUrl/$path.json').replace(queryParameters: {'auth': auth})
      // the emulator serves the project's default database under this name, with the rules from firebase.json
      : Uri.parse(
          'http://$databaseEmulatorHost/$path.json',
        ).replace(queryParameters: {'ns': '$projectId-default-rtdb', 'auth': auth});

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
