import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => HelpScreenState();
}

class HelpScreenState extends State<HelpScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  String? _userId;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
        _userEmail = user.email;
        _emailController.text = _userEmail ?? '';
      });
    }
  }

  Future<void> _checkAndCreateUserDocument() async {
    if (_userId != null) {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('USER').doc(_userId);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        await userDoc.set({
          'uid': _userId,
          'email': _userEmail,
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    String email = _emailController.text.trim();
    String feedback = _feedbackController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_userId != null) {
      await _checkAndCreateUserDocument();

      // Generate document ID based on today's date (DD/MM/YYYY)
      String docId = DateFormat('yyyy/MM/DD').format(DateTime.now());

      await FirebaseFirestore.instance.collection('FEEDBACK').doc(docId).set({
        'uid': _userId,
        'email': email,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(), // Add timestamp to the document
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      _feedbackController.clear();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Feedback',
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
              if (_userId != null)
                Text(
                  'User ID: $_userId',
                  style: const TextStyle(color: Colors.white, fontFamily: 'Cardo'),
                ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF413E3E),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                margin: const EdgeInsets.only(bottom: 20),
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Cardo'),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF413E3E),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                margin: const EdgeInsets.only(bottom: 20),
                child: TextField(
                  controller: _feedbackController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Cardo'),
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter your feedback',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(color: Colors.white),
                  backgroundColor: const Color(0xFF413E3E),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Submit', style: TextStyle(color: Colors.white, fontFamily: 'Cardo')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
