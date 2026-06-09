import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nakila/screens/HomeScreen.dart';
import 'package:nakila/screens/SignInScreen.dart';
import 'screens/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Future<bool> _firebaseInitFuture = _initializeFirebase();

  static Future<bool> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        webProvider: ReCaptchaV3Provider(
          '6Le0uVorAAAAAAZco5gPJwx8kV8sSpBzkOVy0B9l',
        ),
      );
      return true;
    } catch (e, stack) {
      debugPrint('Firebase initialization failed: $e');
      debugPrint('$stack');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KampusFinder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: FutureBuilder<bool>(
        future: _firebaseInitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError || snapshot.data == false) {
            return const NoFirebaseScreen();
          }
          return const EntryScreen();
        },
      ),
    );
  }
}

class NoFirebaseScreen extends StatelessWidget {
  const NoFirebaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F3FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFF0288D1),
                size: 72,
              ),
              const SizedBox(height: 24),
              const Text(
                'Firebase belum dikonfigurasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aplikasi berjalan dengan fitur terbatas. Hubungkan Firebase atau tambahkan konfigurasi terlebih dahulu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => MyApp()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: const Text('Muat ulang setelah konfigurasi Firebase'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(

      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F3FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Image.asset(
                'assets/Additional/Polosan.png',
                height: 250,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Selamat Datang di KampusFinder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Jelajahi kampus terbaik dunia dan temukan universitas yang sesuai untuk masa depanmu.',
              style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 16,
                ),
                child: const Text(
                  'Mulai Cari Kampus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

