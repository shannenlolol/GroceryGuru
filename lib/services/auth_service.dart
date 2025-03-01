import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verifies the provided phone number.
  ///
  /// [phoneNumber]: The phone number to verify.
  /// [codeSent]: Callback when the verification code is sent.
  /// [verificationCompleted]: Callback when the phone number is automatically verified.
  /// [verificationFailed]: Callback when verification fails.
  /// [codeAutoRetrievalTimeout]: Callback for auto retrieval timeout.
  ///
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? forceResendingToken)
        codeSent,
    required void Function(PhoneAuthCredential credential)
        verificationCompleted,
    required void Function(FirebaseAuthException error) verificationFailed,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// Signs in a user with the provided [PhoneAuthCredential].
  Future<UserCredential?> signInWithCredential(
      PhoneAuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
