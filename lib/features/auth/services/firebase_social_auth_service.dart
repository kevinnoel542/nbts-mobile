import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nbts/features/auth/models/social_auth_provider.dart';

class FirebaseSocialAuthResult {
  const FirebaseSocialAuthResult({
    required this.provider,
    required this.idToken,
    this.email,
    this.name,
    this.photoUrl,
    this.uid,
  });

  final SocialAuthProvider provider;
  final String idToken;
  final String? email;
  final String? name;
  final String? photoUrl;
  final String? uid;
}

class FirebaseSocialAuthService {
  const FirebaseSocialAuthService._();

  static Future<FirebaseSocialAuthResult?> signIn(
    SocialAuthProvider provider,
  ) async {
    await Firebase.initializeApp();

    switch (provider) {
      case SocialAuthProvider.google:
        return _signInWithGoogle();
      case SocialAuthProvider.apple:
        return _signInWithApple();
    }
  }

  static Future<void> signOut() async {
    await Firebase.initializeApp();
    await firebase_auth.FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  static Future<FirebaseSocialAuthResult?> _signInWithGoogle() async {
    final googleUser = await GoogleSignIn(
      scopes: <String>['email', 'profile'],
    ).signIn();

    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await firebase_auth.FirebaseAuth.instance
        .signInWithCredential(credential);

    return _resultFromCredential(SocialAuthProvider.google, userCredential);
  }

  static Future<FirebaseSocialAuthResult?> _signInWithApple() async {
    final provider =
        firebase_auth.OAuthProvider(SocialAuthProvider.apple.firebaseProviderId)
          ..addScope('email')
          ..addScope('name');

    final userCredential = await firebase_auth.FirebaseAuth.instance
        .signInWithProvider(provider);

    return _resultFromCredential(SocialAuthProvider.apple, userCredential);
  }

  static Future<FirebaseSocialAuthResult?> _resultFromCredential(
    SocialAuthProvider provider,
    firebase_auth.UserCredential credential,
  ) async {
    final user = credential.user;
    if (user == null) return null;

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) return null;

    return FirebaseSocialAuthResult(
      provider: provider,
      idToken: idToken,
      email: user.email,
      name: user.displayName,
      photoUrl: user.photoURL,
      uid: user.uid,
    );
  }
}
