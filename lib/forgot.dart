import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  ForgotPageState createState() => ForgotPageState();
}

class ForgotPageState extends State<ForgotPage> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail(BuildContext context) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final email = emailController.text.trim();

      // Query Firestore to check if the user exists
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('USER')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          errorMessage = "Email not found. Please enter a valid email address.";
          isLoading = false;
        });
        return;
      }

      // If the email exists, send the password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Show a popup dialog to inform the user
      _showResetEmailSentDialog(context);
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showResetEmailSentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Password Reset Email Sent'),
          content: const Text('Password reset email sent. Please check your email.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
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
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: 28,
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
                            controller: emailController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email, color: Colors.grey),
                              labelText: 'Enter your email address',
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
                              errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                                borderRadius: BorderRadius.all(Radius.circular(28.0)),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                                borderRadius: BorderRadius.all(Radius.circular(28.0)),
                              ),
                              errorText: errorMessage,
                              errorStyle: const TextStyle(
                                color: Colors.red,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0,
                                    color: Colors.black,
                                    offset: Offset(0.5, 0.5),
                                  ),
                                ],
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isLoading ? null : () => _sendPasswordResetEmail(context),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Cardo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Music is the divine way to tell beautiful, poetic things to the heart',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Cardo',
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Image.asset(
                    'assets/images/brand.png',
                    width: 70,
                    height: 70,
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
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
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
