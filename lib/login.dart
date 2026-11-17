import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Please fill in both email and password.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userUid = userCredential.user!.uid;

      // Update user's login status and UID in SharedPreferences
      await _updateLoginStatus(true, userUid);

      // Navigate to the app page with user UID as route argument
      Navigator.pushReplacementNamed(context, '/app', arguments: userUid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showErrorDialog("No such email found. Please register first!");
      } else if (e.code == 'wrong-password') {
        _showErrorDialog("Invalid email or password. Please try again.");
      } else {
        _showErrorDialog(e.message ?? "An error occurred. Please try again.");
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showErrorDialog("An error occurred. Please try again.");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLoginStatus(bool isLoggedIn, String userUid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
    await prefs.setString('userUid', userUid); // Store user UID
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/blur.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 23,
            left: 1,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Image.asset(
                'assets/images/back.png',
                width: 79,
                height: 100,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/brand.png',
                    width: 250,
                    height: 250,
                  ),
                  const Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontFamily: 'Cardo',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF202FF),
                          Color(0xFF7334F1),
                          Color(0xFF2B00FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF4F068C),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email, color: Colors.grey),
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                color: Colors.black,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.all(Radius.circular(28.0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF6A00F4)),
                                borderRadius: BorderRadius.all(Radius.circular(28.0)),
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                          const Divider(),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              labelText: 'Password',
                              labelStyle: const TextStyle(
                                color: Colors.black,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.all(Radius.circular(28.0)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF6A00F4)),
                                borderRadius: BorderRadius.all(Radius.circular(28.0)),
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login, // Disable button if loading
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Cardo',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/forgot');
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Cardo',
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Music is the strongest form of magic',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cardo',
                    ),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/register');
                    },
                    text: 'Create an account',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const GradientButton({
    required this.onPressed,
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B00FF), Color(0xFF7334F1), Color(0xFFDD6BFF), Color(0xFFF202FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'Cardo',
          ),
        ),
      ),
    );
  }
}
