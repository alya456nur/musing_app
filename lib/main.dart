import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:musing_app/player_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import dart files
import 'download_provider.dart';
import 'like_button_provider.dart';
import 'login.dart';
import 'my_player.dart';
import 'register.dart';
import 'forgot.dart';
import 'home.dart';
import 'download.dart';
import 'local.dart';
import 'history.dart';
import 'settings.dart';
import 'Q&A.dart';
import 'edit.dart';
import 'editEmail.dart';
import 'editPass.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();// Ensure Firebase services are initialized
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userUid') ?? '';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => MyPlayerProvider()),
        ChangeNotifierProvider(create: (_) => LikeButtonProvider(userId)),
        ChangeNotifierProvider(create: (_) => DownloadProvider(userId)),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const BrandTransitionPage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/next': (context) => const RegisterScreen(),
        '/forgot': (context) => const ForgotPage(),
        '/app': (context) => const AppScreen(),
        '/downloads': (context) => const DownloadScreen(),
        '/local': (context) => const LocalScreen(),
        '/history': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/Q&A': (context) => const HelpScreen(),
        '/edit': (context) => const EditScreen(),
        '/editEmail': (context) => const EditEmailScreen(),
        '/editPass': (context) => const EditPassScreen(),
      },
    );
  }
}

Offset finalOffsetFromBrandTransitionPage = const Offset(0.0, -0.65);

class BrandTransitionPage extends StatefulWidget {
  const BrandTransitionPage({super.key});

  @override
  BrandTransitionPageState createState() => BrandTransitionPageState();
}

class BrandTransitionPageState extends State<BrandTransitionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(0.0, -0.65),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Start the animation and handle navigation based on login status
    _controller.forward().then((_) async {
      bool isLoggedIn = await _checkLoginStatus();
      if (isLoggedIn) {
        String userUid = await _getUserUid();
        Navigator.pushReplacementNamed(context, '/app', arguments: userUid);
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  Future<bool> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<String> _getUserUid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userUid') ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8c52ff),
      body: Center(
        child: SlideTransition(
          position: _offsetAnimation,
          child: Image.asset(
            'assets/images/brand.png',
            width: 300,
            height: 300,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * (1 + finalOffsetFromBrandTransitionPage.dy) / 2 - 78,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Image.asset(
              'assets/images/brand.png',
              width: 300,
              height: 300,
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 140,
            top: MediaQuery.of(context).size.height / 2,
            child: GradientOutlinedButton(
              text: 'Login',
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              borderColor: Colors.blue,
              borderWidth: 2.0,
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 140,
            top: MediaQuery.of(context).size.height / 2 + 70,
            child: GradientOutlinedButton(
              text: 'Sign Up',
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              borderColor: Colors.green,
              borderWidth: 2.0,
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 120,
            top: MediaQuery.of(context).size.height / 2 + 150,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 240,
              ),
              child: const Text(
                'Music gives a soul to the universe, wings to the mind, '
                    'flight to imagination, and life to everything',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.0,
                  fontFamily: 'Cardo',
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color borderColor;
  final double borderWidth;

  const GradientOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2B00FF),
            Color(0xFF7334F1),
            Color(0xFFDD6BFF),
            Color(0xFFF202FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: BorderSide(
            color: Colors.black,
            width: borderWidth,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cardo',
          ),
        ),
      ),
    );
  }
}

