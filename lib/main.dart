import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'Homepage.dart';
import 'package:lottie/lottie.dart';
import 'intro_page.dart';
import 'data_usage_manager.dart';
import 'admin_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Authenticate with admin key
  await authenticateWithAdminKey();

  // Initialize data usage tracking (reset after clean)
  await DataUsageManager.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coupling Together',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: IntroPage1(),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});



  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  // final CTUsageResetManager _resetManager = CTUsageResetManager();
  @override
  void initState() {
    super.initState();
    _performStartupTasks();
    // _resetManager.checkAndResetIfNewDay();
  }

  Future<void> _performStartupTasks() async {
    try {
      // Confirm key exists (auth already done in main)
      final keySnapshot = await FirebaseDatabase.instance
          .ref('auth_key/key')
          .get();
      debugPrint("🔑 Auth key confirmed: ${keySnapshot.value}");

      // Wait a short time to ensure rules are applied
      await Future.delayed(const Duration(seconds: 3));

      // Navigate to main screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } catch (e) {
      debugPrint("❌ Startup task error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/TrailLoading.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              repeat: true,
            ),
            const SizedBox(height: 20),
            const Text(
              "Preparing app...",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}