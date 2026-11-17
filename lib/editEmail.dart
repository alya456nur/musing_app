import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEmailScreen extends StatefulWidget {
  const EditEmailScreen({super.key});

  @override
  State<EditEmailScreen> createState() => EditEmailScreenState();
}

class EditEmailScreenState extends State<EditEmailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController oldEmailController = TextEditingController();
  final TextEditingController newEmailController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    oldEmailController.dispose();
    newEmailController.dispose();
    super.dispose();
  }

  Future<bool> _checkEmailExists(String email) async {
    final result = await FirebaseFirestore.instance
        .collection('USER')
        .where('email', isEqualTo: email)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<void> _updateEmail() async {
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

    final oldEmail = oldEmailController.text.trim();
    final newEmail = newEmailController.text.trim();

    if (oldEmail != user.email) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Old email does not match the current email.')),
      );
      return;
    }

    if (newEmail == user.email) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New email is the same as the current email.')),
      );
      return;
    }

    if (!newEmail.endsWith('@gmail.com')) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email format.')),
      );
      return;
    }

    final emailExists = await _checkEmailExists(newEmail);
    if (emailExists) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New email already exists.')),
      );
      return;
    }

    try {
      await user.verifyBeforeUpdateEmail(newEmail);
      await FirebaseFirestore.instance.collection('USER').doc(user.uid).update({'email': newEmail});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A verification email has been sent to your new email address. Please verify to complete the update.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating email: $e')),
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
          'Change Email',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cardo',
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // Change the color of back arrow
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
                controller: oldEmailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Old Email Address',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF413E3E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: newEmailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Email Address',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF413E3E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isLoading ? null : _updateEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF413E3E), // Use backgroundColor
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
