// lib/register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:aplikasi_mobile/services/notification_service.dart'; // Tambahan import
import 'package:aplikasi_mobile/services/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller untuk mengambil teks dari inputan
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Variabel untuk state checkbox
  bool _isAgreed = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    // Selalu dispose controller untuk menghindari memory leak
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Taruh fungsi ini di dalam class _RegisterScreenState

  Future<void> _registerUser() async {
    // 1. Validasi Input
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua field harus diisi!')));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok!')),
      );
      return;
    }
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Syarat & Ketentuan.'),
        ),
      );
      return;
    }

    // Tampilkan loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Buat user di Firebase Authentication
      print("STEP A - Mulai createUser");

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      print("STEP B - createUser BERHASIL");

      // 3. Simpan Username ke Firebase Auth (Bukan ke Firestore)
      if (userCredential.user != null) {
        print("STEP C - user != null");
        // Update displayName dengan username yang diinput
        await userCredential.user!.updateDisplayName(
          _usernameController.text.trim(),
        );
        print("STEP D - updateDisplayName BERHASIL");

        // Refresh data user agar displayName terbaru terbaca
        await userCredential.user!.reload();
        print("STEP E - reload BERHASIL");

        // Ambil ulang data user dari Firebase
        final user = FirebaseAuth.instance.currentUser!;

        // Simpan data user ke MySQL
        bool isMySqlSuccess = await DatabaseHelper.instance.simpanUserKeMySQL(
          user.uid,
          user.displayName ?? '',
          user.email ?? '',
        );
        print("STEP F - MySQL BERHASIL? $isMySqlSuccess");

        // Simpan notifikasi selamat datang ke lonceng
        await NotificationService().simpanNotifKeLonceng(
          kategori: 'sistem',
          judul: 'Selamat Datang!',
          pesan:
              'Terima kasih telah bergabung di Cinev App. Nikmati fitur premium gratis bulan ini!',
        );
        print("STEP G - Notification BERHASIL");

        // Kirim email verifikasi ke pengguna
        await user.sendEmailVerification();
        print("STEP H - Email Verification BERHASIL");
        // 4. Tampilkan pesan sukses dan kembali ke halaman login
        if (mounted) {
          String pesanSukses = isMySqlSuccess
              ? 'Pendaftaran Berhasil! Silakan cek email Anda untuk verifikasi sebelum login.'
              : 'Pendaftaran Firebase berhasil, TAPI gagal menyimpan ke MySQL (cek koneksi XAMPP/Firewall).';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pesanSukses),
              duration: const Duration(seconds: 8), 
              backgroundColor: isMySqlSuccess ? Colors.green : Colors.orange,
            ),
          );
          // Keluarkan pengguna dari sesi saat ini agar mereka harus login manual
          await FirebaseAuth.instance.signOut();
          // Kembali ke halaman LoginScreen
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      // 5. Tangani Error dari Firebase
      String message = 'Terjadi kesalahan.';
      if (e.code == 'weak-password') {
        message = 'Kata sandi terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email ini sudah terdaftar.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e, stackTrace) {
      print("================ ERROR =================");
      print(e);
      print(stackTrace);
      print("========================================");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      // Hilangkan loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // lalu ganti dengan kode ini:
  @override
  Widget build(BuildContext context) {
    // Helper widget untuk input field agar tidak duplikat kode
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
              obscureText: isPassword,
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
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      // Kita tidak pakai SafeArea di sini agar gradasi bisa sampai ke tepi layar
      body: Container(
        // Menambahkan gradasi di border seperti desain
        color: const Color(0xFF0A0A0A),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            // "Kartu" utama di tengah
            // lalu ganti dengan kode ini:
            // Container untuk border gradasi
            child: Container(
              padding: const EdgeInsets.all(2.0), // Lebar border
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  26,
                ), // Radius sedikit lebih besar
                gradient: const SweepGradient(
                  // Gradasi warna pelangi
                  colors: [
                    Colors.purple,
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.purple,
                  ],
                ),
              ),
              // "Kartu" utama di tengah
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C27), // Warna background kartu
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  // ... (isi dari column tidak berubah)
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- HEADER ---
                    const Text(
                      'Buat Akun Baru',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daftar untuk memulai jelajahi film',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),

                    // --- INPUT FIELDS ---
                    buildInputField(
                      icon: Icons.person_outline,
                      hintText: 'Username',
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 20),
                    buildInputField(
                      icon: Icons.email_outlined,
                      hintText: 'Email',
                      controller: _emailController,
                    ),
                    const SizedBox(height: 20),
                    // --- KATA SANDI DENGAN IKON MATA ---
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: Colors.white70,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText:
                                !_isPasswordVisible, // Teks tersembunyi jika isPasswordVisible = false
                            decoration: InputDecoration(
                              hintText: 'Kata Sandi',
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  // Ganti ikon berdasarkan state
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  // Ubah state saat tombol ditekan
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // --- KONFIRMASI KATA SANDI DENGAN IKON MATA ---
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_reset_outlined,
                          color: Colors.white70,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Konfirmasi Kata Sandi',
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- CHECKBOX ---
                    Row(
                      children: [
                        Checkbox(
                          value: _isAgreed,
                          activeColor: const Color(
                            0xFF8A60FF,
                          ), // Warna saat di-check
                          onChanged: (bool? value) {
                            setState(() {
                              _isAgreed = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(text: 'Saya setuju dengan '),
                                TextSpan(
                                  text: 'Syarat & Ketentuan',
                                  style: const TextStyle(
                                    color: Color(0xFF8A60FF),
                                  ),
                                  // recognizer: TapGestureRecognizer()..onTap = () { /* Navigasi ke halaman S&K */ },
                                ),
                                const TextSpan(text: ' & '),
                                TextSpan(
                                  text: 'Kebijakan Privasi',
                                  style: const TextStyle(
                                    color: Color(0xFF8A60FF),
                                  ),
                                  // recognizer: TapGestureRecognizer()..onTap = () { /* Navigasi ke halaman privasi */ },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- TOMBOL DAFTAR ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor:
                              Colors.transparent, // Important for gradient
                          shadowColor: Colors.transparent,
                        ).copyWith(elevation: WidgetStateProperty.all(0)),
                        child: Ink(
                          decoration: BoxDecoration(
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
                            height: 50, // Sesuaikan tinggi dengan padding
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Daftar Akun',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- SOCIAL MEDIA LOGIN (HANYA UI) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialIcon(FontAwesomeIcons.facebook),
                        _buildSocialIcon(FontAwesomeIcons.google),
                        _buildSocialIcon(
                          FontAwesomeIcons.xTwitter,
                        ), // Ikon X (Twitter baru)
                        _buildSocialIcon(FontAwesomeIcons.linkedinIn),
                        _buildSocialIcon(FontAwesomeIcons.apple),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- LINK KE HALAMAN LOGIN ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sudah Punya Akun? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            'Masuk Sekarang',
                            style: TextStyle(
                              color: Color(0xFF8A60FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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

  // Helper widget untuk ikon social media
  Widget _buildSocialIcon(IconData icon) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[850],
      child: Icon(icon, color: Colors.white),
    );
  }
}
