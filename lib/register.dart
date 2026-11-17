import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailExists = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    if (_emailExists) {
      setState(() {
        _emailExists = false;
      });
    }
  }

  Future<bool> _isEmailExists(String email) async {
    try {
      // Attempt to create a user with the provided email and a dummy password
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: "dummyPassword1234!",
      );
      // If the above line does not throw, delete the created user immediately
      User? user = FirebaseAuth.instance.currentUser;
      await user?.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return true;
      } else {
        rethrow; // Rethrow unexpected exceptions
      }
    }
  }

  void _register(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      bool emailExists = await _isEmailExists(email);

      setState(() {
        _isLoading = false;
        _emailExists = emailExists;
      });

      if (!emailExists) {
        Navigator.pushNamed(
          context,
          '/next',
          arguments: {'email': email},
        );
      } else {
        _formKey.currentState?.validate();
      }
    }
  }

  void _dismissKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.focusedChild?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _dismissKeyboard(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          child: Stack(
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
                child: GestureDetector(
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
                padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/brand.png',
                        width: 250,
                        height: 250,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontFamily: 'Cardo',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Container(
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
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                                    labelText: 'Enter your email address',
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
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                      borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                      borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                    ),
                                    errorStyle: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                                        Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                                        Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                                        Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                                      ],
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: _emailExists ? Colors.red : Colors.black,
                                    fontSize: 16.0,
                                    decoration: TextDecoration.none,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(value)) {
                                      return 'Please enter a valid email format';
                                    } else if (_emailExists) {
                                      return 'Email already exists. Please use \nanother email.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton(
                                  onPressed: () => _register(context),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    backgroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 50,
                                      vertical: 15,
                                    ),
                                  ),
                                  child: const Text(
                                    'Next',
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
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Music expresses that which cannot be said and on which it is impossible to be silent',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Cardo',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 70),
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Cardo',
                        ),
                      ),
                      const SizedBox(height: 10),
                      GradientButton(
                        text: 'Log In Account',
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                      Image.asset(
                        'assets/images/brand.png',
                        width: 70,
                        height: 70,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  late String _email; // To store the passed email
  bool _isPasswordVisible = false;
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _phoneError = ''; // Variable to store phone number error
  bool _isLoading = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _email = args?['email'] ?? '';
  }

  Future<bool> _isPhoneNumberUnique(String fullPhoneNumber) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('USER')
        .where('phoneNumber', isEqualTo: fullPhoneNumber)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  Future<void> _createUserAccount(String fullPhoneNumber) async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email,
        password: _passwordController.text,
      );

      String uid = userCredential.user?.uid ?? '';

      // Fetch the default profile picture URL
      String defaultProfilePicUrl = await FirebaseStorage.instance
          .ref('pic/profile.png')
          .getDownloadURL();

      await FirebaseFirestore.instance.collection('USER').doc(uid).set({
        'email': _email,
        'username': _usernameController.text,
        'phoneNumber': fullPhoneNumber,
        'password': _passwordController.text,
        'regisDate': Timestamp.now(),
        'pic': defaultProfilePicUrl,
        'premium': false,
        'maxDownloads': 10,
        'downloadVia': 'Via Wi-Fi only',
      });

      setState(() {
        _isLoading = false;
      });

      // Show dialog with loading indicator
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing dialog by tapping outside
        builder: (BuildContext context) {
          return const AlertDialog(
            title: Text('Creating Account...'),
            content: SizedBox(
              height: 64,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        },
      );

      // Close loading dialog after a short delay (simulating account creation)
      await Future.delayed(const Duration(seconds: 2)); // Replace with actual account creation logic

      // Close loading dialog and show success dialog
      Navigator.of(context).pop(); // Close loading dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Account Created Successfully'),
            content: const Text('You may log in to your account now.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.message ?? 'An error occurred. Please try again.');
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
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
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Allows the layout to adjust when the keyboard is open
      body: Stack(
        children: [
          // Background Image
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
                Navigator.of(context).pop(); // Navigate back to previous screen
              },
              child: Image.asset(
                'assets/images/back.png', // Replace with your back button image path
                width: 79,
                height: 100,
                // Adjust width and height as per your image size
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 70),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontFamily: 'Cardo',
                    ),
                  ),
                  const SizedBox(height: 20), // Add some spacing
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _usernameController,
                              maxLength: 20,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person, color: Colors.grey), // Icon color
                                labelText: 'Enter your username',
                                labelStyle: TextStyle(
                                  color: Colors.black, // Label color
                                ),
                                filled: true, // Enables filling the background
                                fillColor: Colors.white, // Background color
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.transparent),
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF6A00F4)), // Focused border color
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                errorStyle: TextStyle(
                                  color: Colors.red, // Error text color
                                  fontSize: 14.0, // Error text size
                                  fontWeight: FontWeight.bold, // Error text weight
                                  shadows: [
                                    Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                                    Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                                    Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                                    Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                                  ],
                                  decoration: TextDecoration.none, // No underline decoration
                                ),
                              ),
                              style: const TextStyle(color: Colors.black), // Text color
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Username cannot be empty';
                                }
                                if (value.length > 20) {
                                  return 'Username cannot be more than 20 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _phoneController,
                              maxLength: 10,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.phone, color: Colors.grey), // Icon color
                                labelText: 'Enter your phone number',
                                prefixText: '+60',
                                labelStyle: TextStyle(
                                  color: Colors.black, // Label color
                                ),
                                filled: true, // Enables filling the background
                                fillColor: Colors.white, // Background color
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.transparent),
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF6A00F4)), // Focused border color
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                errorStyle: TextStyle(
                                  color: Colors.red, // Error text color
                                  fontSize: 14.0, // Error text size
                                  fontWeight: FontWeight.bold, // Error text weight
                                  shadows: [
                                    Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                                    Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                                    Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                                    Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                                  ],
                                  decoration: TextDecoration.none, // No underline decoration
                                ),
                              ),
                              style: const TextStyle(color: Colors.black), // Text color
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Phone number cannot be empty';
                                }
                                if (!RegExp(r'^[0-9]{9,10}$').hasMatch(value) || value.length < 9) {
                                  return 'Invalid phone number format.';
                                }
                                return null;
                              },
                            ),
                            if (_phoneError.isNotEmpty) ...[
                              Text(
                                _phoneError,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                                    Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                                    Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                                    Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock, color: Colors.grey), // Icon color
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
                                  color: Colors.black, // Label color
                                ),
                                filled: true, // Enables filling the background
                                fillColor: Colors.white, // Background color
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.transparent),
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF6A00F4)), // Focused border color
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
                                errorStyle: const TextStyle(
                                  color: Colors.red, // Error text color
                                  fontSize: 14.0, // Error text size
                                  fontWeight: FontWeight.bold, // Error text weight
                                  shadows: [
                                    Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                                    Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                                    Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                                    Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                                  ],
                                  decoration: TextDecoration.none, // No underline decoration
                                ),
                              ),
                              style: const TextStyle(color: Colors.black), // Text color
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password cannot be empty';
                                }
                                else if (value.length < 6) {
                                  return 'Password need to be at least 6 \ncharacters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isPasswordVisible,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.lock, color: Colors.grey), // Icon color
                                labelText: 'Confirm Password',
                                labelStyle: TextStyle(
                                  color: Colors.black, // Label color
                                ),
                                filled: true, // Enables filling the background
                                fillColor: Colors.white, // Background color
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.transparent),
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF6A00F4)), // Focused border color
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.all(Radius.circular(28.0)),
                                ),
                                errorStyle: TextStyle(
                                  color: Colors.red, // Error text color
                                  fontSize: 14.0, // Error text size
                                  fontWeight: FontWeight.bold, // Error text weight
                                  shadows: [
                                    Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                                    Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                                    Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                                    Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                                  ],
                                  decoration: TextDecoration.none, // No underline decoration
                                ),
                              ),
                              style: const TextStyle(color: Colors.black), // Text color
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirm Password cannot be empty';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () async {
                                setState(() {
                                  _phoneError = '';
                                });

                                if (_formKey.currentState!.validate()) {
                                  // Perform the asynchronous phone number check
                                  String fullPhoneNumber = '+60${_phoneController.text}';
                                  bool isUnique = await _isPhoneNumberUnique(fullPhoneNumber);

                                  if (isUnique) {
                                    // Create the user account
                                    await _createUserAccount(fullPhoneNumber);
                                  } else {
                                    setState(() {
                                      _phoneError = 'Phone number already exists. Please use another phone number';
                                    });
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                backgroundColor: Colors.black, // Use backgroundColor instead of primary
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              ),
                              child: const Text(
                                'Create',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'Cardo'
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
          backgroundColor: Colors.transparent, // Important for gradient
          shadowColor: Colors.transparent, // Removes shadow
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
