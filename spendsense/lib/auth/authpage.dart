import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendsense/auth/authcontroller.dart';
import 'package:spendsense/constants/colors/colors.dart';
// === Colors ===
// const Color secondaryColor50 = Color(0xFF6C63FF);
// const Color secondaryColor = Color(0xFF3F3D56);
// const Color whitee = Colors.white;
// const Color gray80 = Color(0xFF4A4A4A);

class AuthPage extends StatelessWidget {
  AuthPage({super.key});

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Ycolor.whitee,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  authController.isLogin.value
                      ? 'Welcome Back!'
                      : 'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Ycolor.secondarycolor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (!authController.isLogin.value) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: authController.isLoading.value
                      ? null
                      : () {
                          if (authController.isLogin.value) {
                            authController.signInWithEmail(
                              _emailController.text,
                              _passwordController.text,
                            );
                          } else {
                            authController.signUpWithEmail(
                              _nameController.text,
                              _emailController.text,
                              _passwordController.text,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Ycolor.secondarycolor50,
                    foregroundColor: Ycolor.whitee,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: authController.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(authController.isLogin.value
                          ? 'Sign In'
                          : 'Sign Up'),
                ),

                const SizedBox(height: 16),

                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("or"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                OutlinedButton(
                  onPressed: authController.isLoading.value
                      ? null
                      : authController.signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Ycolor.gray80),
                    foregroundColor: Ycolor.secondarycolor,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google_logo.png',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                if (authController.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    authController.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                TextButton(
                  onPressed: authController.toggleLoginSignup,
                  child: Text(
                    authController.isLogin.value
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Sign In",
                    style: TextStyle(color: Ycolor.gray80),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
