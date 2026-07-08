import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- SESUAIKAN IMPORT INI DENGAN NAMA FILE KAMU YAA ---
import 'package:aplikasi_mobile/login_screen.dart'; 
import 'package:aplikasi_mobile/halaman_utama.dart'; // Ganti jika nama file berandamu berbeda

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _sudahPindahHalaman = false; // Mencegah pindah halaman dobel

  @override
  void initState() {
    super.initState();
    
    // 1. Inisialisasi video dari folder assets
    _controller = VideoPlayerController.asset('assets/images/splash_animasi.mp4')
      ..initialize().then((_) {
        // Setelah mesin video siap, paksa layar update dan putar videonya
        setState(() {});
        _controller.play();
      });

    // 2. Pasang "CCTV" untuk memantau durasi video
    _controller.addListener(() {
      // Jika video sudah jalan sampai akhir detik (selesai)
      if (_controller.value.isInitialized && 
          _controller.value.position >= _controller.value.duration) {
        _cekStatusLoginDanPindah();
      }
    });
  }

  void _cekStatusLoginDanPindah() {
    // Kunci agar fungsi ini tidak tereksekusi 2 kali
    if (_sudahPindahHalaman) return;
    _sudahPindahHalaman = true;

    // Cek apakah ada user yang sedang nyangkut (sudah login) di memori HP
    User? user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Opsi A: Sudah Login -> Lempar ke Beranda
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HalamanUtama()), // Pastikan nama Class Berandamu benar
      );
    } else {
      // Opsi B: Belum Login -> Lempar ke Login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Wajib dibuang dari memori saat pindah halaman biar HP nggak lemot
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background hitam pekat sesuai tema Cinev
      backgroundColor: const Color.fromARGB(255, 0, 0, 0), 
      body: Center(
        // Jika video sudah siap, tampilkan. Jika belum, tampilkan kosong (hitam)
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const SizedBox(), 
      ),
    );
  }
}