import 'package:air_reply/core/error/app_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Who this install is to the backend. Both devices sign in anonymously: the Firestore rules only need a stable uid
/// per install to tell the two members of a pair apart.
abstract interface class AuthGateway {
  String? get currentUid;

  Future<String> ensureSignedIn();
}

final class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this._auth);

  final FirebaseAuth _auth;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<String> ensureSignedIn() async {
    if (_auth.currentUser case final User user) return user.uid;
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw SyncException('Could not reach AirReply servers. Check your connection.', cause: e);
    }
  }
}
