import 'package:air_reply/core/error/app_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Who this install is to the backend. Both devices sign in anonymously: the Firestore rules only need a stable uid
/// per install to tell the two members of a pair apart.
abstract interface class AuthGateway {
  String? get currentUid;

  Future<String> ensureSignedIn();

  /// A current ID token of this install, signing in first if needed; [forceRefresh] when the last one was refused.
  Future<String> idToken({bool forceRefresh = false});

  /// Forgets this install's sign-in; with [deleteAccount], deletes its anonymous account on the server too, so
  /// nothing of it is left there.
  Future<void> signOut({bool deleteAccount = false});
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
      throw SyncException(AppError.serverUnreachable, cause: e);
    }
  }

  @override
  Future<void> signOut({bool deleteAccount = false}) async {
    try {
      if (deleteAccount) await _auth.currentUser?.delete();
    } on FirebaseAuthException {
      // the account stays on the server (offline): signed out here all the same
    }
    await _auth.signOut();
  }

  @override
  Future<String> idToken({bool forceRefresh = false}) async {
    await ensureSignedIn();
    final token = await _auth.currentUser!.getIdToken(forceRefresh);
    if (token == null) throw const SyncException(AppError.serverUnreachable);
    return token;
  }
}
