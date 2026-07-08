// lib/login_screen.dart
import 'package:aplikasi_mobile/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/halaman_utama.dart'; // Untuk navigasi setelah login
import 'package:firebase_auth/firebase_auth.dart'; // Untuk autentikasi
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:aplikasi_mobile/services/notification_service.dart'; // Import service notif
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aplikasi_mobile/services/database_helper.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk mengambil teks dari inputan
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> loginDenganGoogle(BuildContext context) async {
    try {
      // 1. Autentikasi (Mendapatkan Identitas)
      final googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) return; 

      // 2. Mendapatkan idToken (Bukti Identitas User)
      final googleAuth = await googleUser.authentication;

      // 3. Otorisasi (Mendapatkan Izin Akses / accessToken)
      final List<String> scopes = ['email', 'profile'];
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(scopes);

      // 4. Meracik Token untuk Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: clientAuth.accessToken, 
      );

      // 5. Mendaftarkan/Login ke Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // 6. Cek apakah berhasil masuk
      if (userCredential.user != null) {
        print("BERHASIL LOGIN! Nama: ${userCredential.user!.displayName}");
        
        // --- TAMBAHAN BARU: PICU NOTIFIKASI & LONCENG ---
        // Ambil nama dari akun Google, jika kosong beri nama default 'Sobat Cinev'
        String namaPengguna = userCredential.user?.displayName ?? 'Sobat Cinev';

        // Simpan / Update user ke MySQL (wajib agar sinkron)
        await DatabaseHelper.instance.simpanUserKeMySQL(
          userCredential.user!.uid,
          namaPengguna,
          userCredential.user!.email ?? '',
        );
        
        // Munculkan pop-up Selamat Datang di atas layar HP
        await NotificationService().tampilkanNotifikasiWelcome(
          username: namaPengguna,
        );

        // Simpan catatan riwayat masuk secara senyap ke database Lonceng
        await NotificationService().simpanNotifKeLonceng(
          kategori: 'login',
          judul: 'Keamanan Akun',
          pesan: 'Akun berhasil masuk menggunakan akun Google.',
        );
        // -------------------------------------------------

        // 7. Navigasi aman ke Halaman Utama (membersihkan riwayat login)
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HalamanUtama()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      print("ERROR GOOGLE SIGN-IN: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal login dengan Google: $e')),
        );
      }
    }
  }

  Future<void> _loginUser() async {
    // 1. Validasi Input
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan kata sandi harus diisi!')),
      );
      return;
    }

    // Tampilkan loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Proses Login dengan Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Cek apakah email sudah diverifikasi
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // Jika belum diverifikasi, paksa logout dan tampilkan pesan
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email Anda belum diverifikasi. Silakan cek kotak masuk atau spam email Anda.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }

        setState(() {
          _isLoading = false; // Matikan loading
        });

        return; // Hentikan fungsi di sini, jangan lanjut ke halaman utama
      }

      // Refresh data user agar informasi terbaru terbaca
      await userCredential.user!.reload();

      // Ambil ulang data user
      final user = FirebaseAuth.instance.currentUser!;

      // Simpan / Update user ke MySQL
      await DatabaseHelper.instance.simpanUserKeMySQL(
        user.uid,
        user.displayName ?? '',
        user.email ?? '',
      );

      // Ambil nama pengguna, lalu munculkan notifikasi Selamat Datang dari atas layar
      String namaPengguna = user.displayName ?? 'Sobat Cinev';
      await NotificationService().tampilkanNotifikasiWelcome(
        username: namaPengguna,
      );

      // Simpan riwayat login ke lonceng
      await NotificationService().simpanNotifKeLonceng(
        kategori: 'login',
        judul: 'Keamanan Akun',
        pesan: 'Akun berhasil masuk pada perangkat ini.',
      );

      // 3. Navigasi ke Halaman Utama jika berhasil dan sudah diverifikasi
      // pushAndRemoveUntil akan menghapus semua halaman sebelumnya (login, splash)
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HalamanUtama()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // 4. Tangani Error dari Firebase
      String message = 'Terjadi kesalahan.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Email atau kata sandi yang Anda masukkan salah.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      // Tangani error umum lainnya
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
      );
    } finally {
      // Hilangkan loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _resetPassword() async {
      // Memastikan user sudah mengisi email sebelum menekan lupa password
      if (_emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Masukkan email kamu terlebih dahulu di kolom Email!',
            ),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Mengirimkan permintaan reset password ke Firebase
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email reset kata sandi telah dikirim! Cek Kotak Masuk atau Spam email kamu.',
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Terjadi kesalahan.';
        if (e.code == 'user-not-found') {
          message = 'Email ini tidak terdaftar di sistem kami.';
        } else if (e.code == 'invalid-email') {
          message = 'Format email tidak valid.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Helper widget untuk input field
    Widget buildInputField({
      required IconData icon,
      required String hintText,
      required TextEditingController controller,
      bool isPassword = false,
    }) {
      return Row(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: isPassword && !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ],
      );
    }

    // Helper widget untuk ikon social media
    Widget buildSocialIcon(IconData icon, {VoidCallback? onTap}) { // <-- Tambahkan parameter onTap
      return GestureDetector( // <-- Bungkus dengan pendeteksi sentuhan
        onTap: onTap,
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[850],
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
    }

    return Scaffold(
      body: Container(
        color: const Color(0xFF0A0A0A), // Background utama
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            // Container untuk border gradasi
            child: Container(
              padding: const EdgeInsets.all(2.0), // Lebar border
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const SweepGradient(
                  colors: [
                    Colors.purple,
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.purple,
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C27),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Login Form',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- INPUT FIELDS ---
                    buildInputField(
                      icon: Icons.person_outline,
                      hintText: 'Email', // Tetap pakai Email
                      controller: _emailController,
                    ),
                    const SizedBox(height: 20),
                    buildInputField(
                      icon: Icons.lock_outline,
                      hintText: 'Password',
                      controller: _passwordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 10),

                    // --- REMEMBER ME & FORGET PASSWORD ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xFF8A60FF),
                              onChanged: (bool? value) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              },
                            ),
                            const Text('Remember me'),
                          ],
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          child: const Text(
                            'Forget Password?',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- TOMBOL LOGIN ---
                    Padding(
                      // Menambahkan jarak di kiri dan kanan tombol
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _loginUser,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero, // Reset padding default
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ).copyWith(elevation: WidgetStateProperty.all(0)),
                          child: Ink(
                            decoration: BoxDecoration(
                              // Gradasi yang sama seperti tombol register
                              gradient: const LinearGradient(
                                colors: [Colors.purple, Colors.indigo],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: 50,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- LINK KE HALAMAN REGISTER ---
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'create account',
                        style: TextStyle(color: Color(0xFF8A60FF)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- SOCIAL MEDIA LOGIN ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildSocialIcon(FontAwesomeIcons.facebook),
                        
                        // KITA UBAH BAGIAN GOOGLE INI:
                        buildSocialIcon(
                          FontAwesomeIcons.google,
                          onTap: () {
                            loginDenganGoogle(context); // Memanggil fungsi sakti lo!
                          },
                        ),
                        
                        buildSocialIcon(FontAwesomeIcons.xTwitter),
                        buildSocialIcon(FontAwesomeIcons.linkedinIn),
                        buildSocialIcon(FontAwesomeIcons.apple),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
