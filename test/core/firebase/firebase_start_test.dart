import 'package:air_reply/core/firebase/firebase_start.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a default app the platform already started is used, not reported as a setup problem', () async {
    await startFirebase(
      initialize: () => throw FirebaseException(plugin: 'core', code: 'duplicate-app', message: 'already exists'),
    );
  });

  test('any other failure still stops start-up, for the setup screen to show', () async {
    await expectLater(
      startFirebase(
        initialize: () => throw FirebaseException(plugin: 'core', code: 'not-initialized'),
      ),
      throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'not-initialized')),
    );
  });
}
