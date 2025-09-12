import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.put(AuthController());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isLogin = true.obs; // toggle login/signup

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      errorMessage.value = '';
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? "Something went wrong";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail(String name, String email, String password) async {
    _setLoading(true);
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await userCred.user?.updateDisplayName(name.trim());
      errorMessage.value = '';
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? "Something went wrong";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      errorMessage.value = '';
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? "Google Sign-In failed";
    } catch (e) {
      errorMessage.value = "Google Sign-In error: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      // Sign out from Firebase
      await _auth.signOut();
      // Also sign out from Google if previously logged in
      await GoogleSignIn().signOut();
      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = "Logout failed: $e";
    } finally {
      _setLoading(false);
    }
  }

  void toggleLoginSignup() {
    isLogin.value = !isLogin.value;
    errorMessage.value = '';
  }

  void _setLoading(bool val) => isLoading.value = val;
}
