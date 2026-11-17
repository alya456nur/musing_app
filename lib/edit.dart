import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => EditScreenState();
}

class EditScreenState extends State<EditScreen> {
  @override
  Widget build(BuildContext context) {
    return const EditView();
  }
}

class EditView extends StatefulWidget {
  const EditView({super.key});

  @override
  EditViewState createState() => EditViewState();
}

class EditViewState extends State<EditView> {
  bool isEditingUsername = false;
  bool isEditingPhoneNumber = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  File? _image;
  String? _profilePictureUrl;
  bool isLoading = false;

  String? _initialUsername;
  String? _initialPhoneNumber;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('USER').doc(user.uid).get();
        String phoneNumber = userDoc['phoneNumber'] ?? '';
        String formattedPhoneNumber = phoneNumber.startsWith('+60') ? phoneNumber.substring(3) : phoneNumber;

        setState(() {
          usernameController.text = userDoc['username'];
          phoneNumberController.text = formattedPhoneNumber;
          _initialUsername = userDoc['username'];
          _initialPhoneNumber = userDoc['phoneNumber']; // Store the full phone number with prefix
          _profilePictureUrl = userDoc['pic'];
          _image = null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user data: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storageRef = FirebaseStorage.instance.ref().child('pic/${user.uid}');
        await storageRef.putFile(image);
        return await storageRef.getDownloadURL();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
    }
    return null;
  }

  Future<bool> _checkPhoneNumberExists(String phoneNumber) async {
    final result = await FirebaseFirestore.instance
        .collection('USER')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<void> _updateUserProfile() async {
    setState(() {
      isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        if (phoneNumberController.text.length < 9) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Invalid phone number format.')));
          setState(() {
            isLoading = false;
          });
          return;
        }

        String updatedPhoneNumber = '+60${phoneNumberController.text}';

        if (updatedPhoneNumber != _initialPhoneNumber) {
          bool phoneNumberExists = await _checkPhoneNumberExists(updatedPhoneNumber);
          if (phoneNumberExists) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Phone number already exists.')));
            setState(() {
              isLoading = false;
            });
            return;
          }
        }

        if (usernameController.text.length > 20) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Username must be 20 characters or less.')));
          setState(() {
            isLoading = false;
          });
          return;
        }

        String? profilePictureUrl;
        if (_image != null) {
          profilePictureUrl = await _uploadImage(_image!);
        }

        Map<String, dynamic> updates = {};
        if (usernameController.text != _initialUsername) {
          updates['username'] = usernameController.text;
        }
        if (updatedPhoneNumber != _initialPhoneNumber) {
          updates['phoneNumber'] = updatedPhoneNumber;
        }
        if (profilePictureUrl != null) {
          updates['pic'] = profilePictureUrl;
        }

        if (updates.isNotEmpty) {
          await FirebaseFirestore.instance.collection('USER').doc(user.uid).update(updates);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No changes detected.')));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error updating profile: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating profile.')));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9011C3),
                  Color(0xFF380262),
                  Color(0xFF000000),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.1, 0.3],
                tileMode: TileMode.clamp,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/images/brand.png',
                    width: 150,
                    height: 80,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 350,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: const Color(0xFFA59C9C),
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : _profilePictureUrl != null
                                  ? NetworkImage(_profilePictureUrl!)
                                  : const AssetImage('assets/images/profile.png') as ImageProvider,
                              child: _image == null && _profilePictureUrl == null
                                  ? const Icon(Icons.camera_alt, color: Colors.white, size: 50)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: usernameController,
                                enabled: isEditingUsername,
                                maxLength: 20,
                                style: TextStyle(color: isEditingUsername ? Colors.white : Colors.grey),
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  labelStyle: const TextStyle(color: Colors.white),
                                  filled: true,
                                  fillColor: const Color(0xFF413E3E),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  counterText: '',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  isEditingUsername = !isEditingUsername;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: phoneNumberController,
                                enabled: isEditingPhoneNumber,
                                maxLength: 10,
                                style: TextStyle(color: isEditingPhoneNumber ? Colors.white : Colors.grey),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  labelStyle: const TextStyle(color: Colors.white),
                                  prefixText: '+60 ',
                                  prefixStyle: TextStyle(color: isEditingPhoneNumber ? Colors.white : Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFF413E3E),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  counterText: '',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  isEditingPhoneNumber = !isEditingPhoneNumber;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/editEmail');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF413E3E),
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                              ),
                              child: const Text(
                                'Change email address',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Cardo',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/editPass');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF413E3E),
                                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
                              ),
                              child: const Text(
                                'Change password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Cardo',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF413E3E),
                                    padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 10),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Cardo',
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: isLoading ? null : _updateUserProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9011C3),
                                    padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 10),
                                  ),
                                  child: const Text(
                                    'Update',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Cardo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
