// lib/main.dart
import 'package:aplikasi_mobile/splash_screen.dart'; // Import file splash screen kita
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:aplikasi_mobile/services/notification_service.dart'; // Import service notif
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Crashlytics
import 'package:google_sign_in/google_sign_in.dart';

// Fungsi wajib di luar class untuk menangani pesan saat aplikasi ditutup
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Daftarkan handler untuk notif saat aplikasi ditutup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Inisialisasi sistem notifikasi lokal
  await NotificationService().initNotification();
  
  // Aktifkan Antena Firebase
  await NotificationService().initFCM();

  // --- TAMBAHAN BARU: Mengaktifkan Crashlytics ---
  // Ini untuk merekam error bawaan dari aplikasi agar masuk ke dashboard dosenmu
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // --- TAMBAHAN BARU: INISIALISASI GOOGLE SIGN-IN ---
  // Taruh Web Client ID kamu di sini agar Google mengenali aplikasimu
  await GoogleSignIn.instance.initialize(
    serverClientId: '422110889291-qfj4311nbncjucqk9tcbih3t9ie3ajvp.apps.googleusercontent.com',
  );
  // --------------------------------------------------
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinev App',
      theme: ThemeData(
        // Kita set tema default jadi gelap sesuai desain
        brightness: Brightness.dark,
        // Atur warna utama aplikasi, bisa disesuaikan
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(
          0xFF1C1C27,
        ), // Warna background gelap
      ),
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      // Halaman pertama yang akan muncul adalah Splash Screen
      home: SplashScreen(),
    );
  }
}