import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/settings/halaman_pengaturan.dart';
import 'package:aplikasi_mobile/halaman_ubah_profil.dart';
import 'package:aplikasi_mobile/halaman_avatar_decoration.dart';
import 'package:aplikasi_mobile/halaman_unduhan.dart';
import 'package:aplikasi_mobile/halaman_premium.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class HalamanProfil extends StatefulWidget {
  const HalamanProfil({super.key});

  @override
  State<HalamanProfil> createState() => _HalamanProfilState();
}

class _HalamanProfilState extends State<HalamanProfil> {
  Stream<User?>? _streamDataPengguna;

  @override
  void initState() {
    super.initState();
    _inisialisasiStream();
  }

  void _inisialisasiStream() {
    // Langsung dengarkan perubahan data akun dari Firebase Auth
    _streamDataPengguna = FirebaseAuth.instance.userChanges();
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // KITA HAPUS STACK, KEMBALI KE STRUKTUR NORMAL
      backgroundColor: const Color(0xFF302E2E),
      body: _streamDataPengguna == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Silakan login untuk melihat profil Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            )
          : StreamBuilder<User?>(
              stream: _streamDataPengguna,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan'));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text('Data pengguna tidak ditemukan'),
                  );
                }

                final user = snapshot.data!;
                final namaPengguna = user.displayName ?? 'Tanpa Nama';
                final urlFotoProfil = user.photoURL;

                // SingleChildScrollView membungkus SEMUANYA
                return SingleChildScrollView(
                  // Kita tidak perlu padding atas di sini
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- INI DIA BAGIAN HEADER ABU-ABU ITU ---
                      Container(
                        width: double.infinity,
                        color: const Color(0xFF444242), // Warna abu-abu
                        height:
                            115, // Tinggi untuk area status bar, sesuaikan jika perlu
                      ),

                      // --- SISA KONTEN (KARTU & MENU) ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          0.0,
                          16.0,
                          16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- INFO PROFIL DIPINDAH KE SINI ---
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: urlFotoProfil != null
                                      ? NetworkImage(urlFotoProfil)
                                      : null,
                                  child: urlFotoProfil == null
                                      ? const Icon(Icons.person, size: 50)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          namaPengguna,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildBadge(
                                            'Member',
                                            Colors.grey[700]!,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildBadge(
                                            'Lv. 230',
                                            Colors.grey[700]!,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildBadge(
                                            '#5215663',
                                            Colors.grey[700]!,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            _buildKartuLevelUp(),
                            const SizedBox(height: 16),
                            // Jarak ke kartu di bawahnya
                            _buildKartuPremium(),
                            const SizedBox(height: 16),

                            // --- KARTU BARU UNTUK MENU ---
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF383636), // Warna kartu
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                // Biar rapi pas di-tap
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  children: [
                                    _buildTombolMenu(
                                      ikonWidget: const Icon(
                                        Icons.edit_outlined,
                                      ),
                                      teks: 'Edit Profile',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HalamanUbahProfil(),
                                          ),
                                        );
                                      },
                                    ),

                                    _buildTombolMenu(
                                      ikonWidget: Image.asset(
                                        // <-- GANTI JADI Image.asset
                                        'assets/images/ikon_avatar.png',
                                        width: 24,
                                        height: 24,
                                        color: Colors
                                            .white70, // Tint warna biar sama kayak ikon lain
                                      ),
                                      teks: 'Avatar Decoration',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HalamanAvatarDecoration(),
                                          ),
                                        );
                                      },
                                    ),

                                    _buildTombolMenu(
                                      ikonWidget: Image.asset(
                                        // <-- GANTI JADI Image.asset
                                        'assets/images/ikon_unduhan.png',
                                        width: 24,
                                        height: 24,
                                        color: Colors
                                            .white70, // Tint warna biar sama kayak ikon lain
                                      ),
                                      teks: 'Unduhan Saya',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HalamanUnduhan(),
                                          ),
                                        );
                                      },
                                    ),

                                    _buildTombolMenu(
                                      ikonWidget: const Icon(
                                        Icons.settings_outlined,
                                      ), // <-- GANTI JADI ikonWidget
                                      teks: 'Pengaturan',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HalamanPengaturan(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // --- SEMUA FUNGSI HELPER DI BAWAH INI TIDAK BERUBAH ---

  Widget _buildKartuLevelUp() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF444242),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.center, // Sejajarkan vertikal
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/ikon_roket.png',
                    width: 24, // Samakan ukurannya
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Level Up',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                // Container +122
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+122',
                  style: TextStyle(
                    color: Color(0xFF36FF18),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Jarak antara baris Level Up dan Progress
          // Baris kedua: Progress & 34%
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.center, // Sejajarkan vertikal
            children: [
              const Text(
                'Progress',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Text(
                // Teks 34% pindah ke sini
                '34%',
                style: TextStyle(
                  color: Color(0xFF36FF18),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Jarak ke progress bar
          // Progress Bar
          LinearProgressIndicator(
            value: 0.34,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF36FF18)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          // Baris Teks Bawah (Cara Mendapatkan XP)
          Row(
            children: [
              Text(
                'Cara Mendapatkan XP',
                style: TextStyle(color: const Color(0xFF36FF18), fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward,
                color: Color(0xFF36FF18),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKartuPremium() {
    Widget buildFiturChip({
      required String text,
      required Widget iconWidget, // <-- UBAH DI SINI
      required Color backgroundColor,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  // <-- Tambahkan const
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          // <-- TAMBAHKAN INI
          image: AssetImage('assets/images/bg_kartu_premium.png'),
          fit: BoxFit.cover, // Biar gambarnya menuhin kartu
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // --- KITA BUNGKUS IKONNYA DENGAN CONTAINER ---
              Container(
                padding: const EdgeInsets.all(6), // Beri sedikit padding
                decoration: const BoxDecoration(
                  color: Color(0xFF151313), // Warna background ikon
                  shape: BoxShape.circle, // Bikin jadi lingkaran
                ),
                child: Image.asset(
                  'assets/images/ikon_kristal.png',
                  width: 20,
                  height: 20,
                  color: const Color(0xFFE4DCDC), // Tetap pakai warna E4DCDC
                ),
              ),
              const SizedBox(width: 12), // Jarak disesuaikan sedikit
              const Text(
                'Upgrade to Premium!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Fitur Premium',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 5,
            children: [
              buildFiturChip(
                text: 'Add-Free Experience',
                iconWidget: const Icon(
                  Icons.not_interested,
                  size: 18,
                  color: Colors.red,
                ),
                backgroundColor: Colors.black.withAlpha(77),
              ),
              buildFiturChip(
                text: 'Emoji Support',
                iconWidget: Image.asset(
                  'assets/images/ikon_emogi.png',
                  width: 18,
                  height: 18,
                ),
                backgroundColor: Colors.black.withAlpha(77),
              ),
              buildFiturChip(
                text: 'Priority Support',
                iconWidget: Image.asset(
                  'assets/images/ikon_support.png',
                  width: 18,
                  height: 18,
                ),
                backgroundColor: Colors.black.withAlpha(77),
              ),
              buildFiturChip(
                text: 'Exclusive Badge',
                iconWidget: Image.asset(
                  'assets/images/badge_verified.png', // <-- Panggil gambar
                  width: 18, // Samakan ukurannya
                  height: 18,
                ),
                backgroundColor: Colors.black.withAlpha(77),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HalamanPremium()),
              );
            },
            icon: const Icon(Icons.star, size: 18),
            label: const Text('Beli Premium Sekarang!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5105DD),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // --- TOMBOL SAKTI UNTUK PRESENTASI ---
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Perintah untuk memaksa aplikasi mati seketika
              FirebaseCrashlytics.instance.crash();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 24, 9, 82),
            ),
            child: const Text(
              "Test Crash",
              style: TextStyle(color: Colors.white),
            ),
          ),
          // ------------------------------------
        ],
      ),
    );
  }


  Widget _buildTombolMenu({
    required Widget ikonWidget,
    required String teks,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: ikonWidget,
      title: Text(teks),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
