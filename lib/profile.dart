import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String? username;
  String? profilePictureUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUserData();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      // Check if the UID has changed (user logged in as a different user)
      setState(() {
        isLoading = true;
      });
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('USER').doc(widget.uid).get();
      setState(() {
        username = userDoc['username'];
        profilePictureUrl = userDoc['pic'] ?? 'gs://musing-7f04b.appspot.com/pic/profile.png'; // Use default if null
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user data: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ProfileView(username: username ?? 'Unknown', profilePictureUrl: profilePictureUrl!);
  }
}


class ProfileView extends StatelessWidget {
  final String username;
  final String profilePictureUrl;

  const ProfileView({super.key, required this.username, required this.profilePictureUrl});

  Future<void> _logout(BuildContext context) async {
    try {
      // Sign out from Firebase Authentication
      await FirebaseAuth.instance.signOut();

      // Clear user session data (optional, if using SharedPreferences)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored data

      // Navigate to the login screen (or home screen)
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (kDebugMode) {
        print('Error logging out: $e');
      }
      // Handle error logging out
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9011C3), // Start color
                  Color(0xFF380262),
                  Color(0xFF000000),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.1, 0.3], // Adjust the stop values
                tileMode: TileMode.clamp, // This is the default, and it ensures the gradient fills the entire area
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Brand image
                Image.asset(
                  'assets/images/brand.png', // Replace with your brand image asset
                  width: 150, // Adjust the width as needed
                  height: 80, // Adjust the height as needed
                ),
                const SizedBox(height: 20),
                Container(
                  width: 350, // Adjust the width as needed
                  margin: const EdgeInsets.only(top: 10), // Adjust the margin as needed
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color(0xFFA59C9C), // Border color
                      width: 2.0, // Border width (thickness)
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(profilePictureUrl),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cardo',
                                ),
                              ),
                              SizedBox(
                                width: 105, // Adjust the width as needed
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/edit');
                                  },
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  label: const Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Cardo',
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFF413E3E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      buildMenuItem(
                        context,
                        'Downloads',
                        'assets/images/download.png', // Replace with your image asset
                        '/downloads',
                      ),
                      buildMenuItem(
                        context,
                        'Local songs',
                        'assets/images/local.png', // Replace with your image asset
                        '/local',
                      ),
                      buildMenuItem(
                        context,
                        'History',
                        'assets/images/history.png', // Replace with your image asset
                        '/history',
                      ),
                      buildMenuItem(
                        context,
                        'Settings',
                        'assets/images/setting.png', // Replace with your image asset
                        '/settings',
                      ),
                      buildMenuItem(
                        context,
                        'Help & Feedback',
                        'assets/images/Q&A.png', // Replace with your image asset
                        '/Q&A',
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _logout(context); // Pass context to _logout method
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF413E3E), // Use backgroundColor
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        ),
                        child: const Text('Log Out', style: TextStyle(color: Colors.white, fontFamily: 'Cardo')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenuItem(BuildContext context, String title, String iconPath, String routeName) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, routeName);
        },
        child: ListTile(
          leading: Image.asset(
            iconPath,
            width: 30,
            height: 30,
            color: Colors.white,
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontFamily: 'Cardo'),
          ),
        ),
      ),
    );
  }
}
