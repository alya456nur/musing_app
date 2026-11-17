import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPassScreen extends StatefulWidget {
  const EditPassScreen({super.key});

  @override
  State<EditPassScreen> createState() => EditPassScreenState();
}

class EditPassScreenState extends State<EditPassScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController oldPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  bool isLoading = false;
  bool _obscureOldPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void dispose() {
    _scrollController.dispose();
    oldPassController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _updatePass() async {
    setState(() {
      isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    final oldPass = oldPassController.text.trim();
    final newPass = newPassController.text.trim();
    final confirmPass = confirmPassController.text.trim();

    if (newPass.length < 6) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password needs to be at least 6 characters.')),
      );
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirm password do not match.')),
      );
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cardo',
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              TextField(
                controller: oldPassController,
                style: const TextStyle(color: Colors.white),
                obscureText: _obscureOldPass,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF413E3E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPass ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureOldPass = !_obscureOldPass;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: newPassController,
                style: const TextStyle(color: Colors.white),
                obscureText: _obscureNewPass,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF413E3E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPass ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPass = !_obscureNewPass;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: confirmPassController,
                style: const TextStyle(color: Colors.white),
                obscureText: _obscureConfirmPass,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF413E3E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPass ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPass = !_obscureConfirmPass;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isLoading ? null : _updatePass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF413E3E),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cardo',
                    fontSize: 18,
                  ),
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
