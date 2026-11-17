import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'download_provider.dart';  // Ensure you have this import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  String downloadOption = 'Over Wi-Fi only';
  List<String> downloadOptions = [
    'Over Wi-Fi only',
    'Over mobile data only',
    'Always ask'
  ];
  String? _userId;

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
      });
    }
  }

  Future<void> _updateDownloadOption(String option) async {
    if (_userId != null) {
      await FirebaseFirestore.instance.collection('USER').doc(_userId).update({
        'downloadVia': option,
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Download via',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      height: 40,
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DropdownButton<String>(
                          value: downloadOption,
                          dropdownColor: Colors.grey[900],
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                downloadOption = value;
                              });
                              _updateDownloadOption(value);
                            }
                          },
                          items: downloadOptions
                              .map((String option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(
                              option,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text(
                          'Clear Downloads?',
                          style: TextStyle(color: Colors.red),
                        ),
                        content: const Text(
                          'Are you sure you want to clear all downloads?',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: () async {
                              final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
                              await downloadProvider.clearDownloads();
                              Navigator.of(context).pop();
                            },
                            child: const Text('CLEAR', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Clear Downloads',
                        style: TextStyle(color: Colors.white),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
