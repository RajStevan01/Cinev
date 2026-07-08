// lib/halaman_pengaturan.dart

import 'package:aplikasi_mobile/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi_mobile/settings/privacy_policy_page.dart';
import 'package:aplikasi_mobile/settings/halaman_syarat_ketentuan.dart';
import 'package:aplikasi_mobile/settings/kontak_kami.dart';

class HalamanPengaturan extends StatelessWidget {
  const HalamanPengaturan({super.key});

  // Fungsi untuk logout
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigasi ke SplashScreen dan hapus semua halaman sebelumnya
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (Route<dynamic> route) => false, // Kondisi ini menghapus semua route
      );
    } catch (e) {
      // Tampilkan pesan jika logout gagal
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal untuk logout: $e')));
    }
  }

  void _showPengaturanDownloadSheet(BuildContext context) {
    // Default: download hanya via Wifi
    bool downloadHanyaWifi = true;

    // Muat pengaturan yang sudah tersimpan
    Future<void> loadSettings() async {
      final prefs = await SharedPreferences.getInstance();
      // Baca pengaturan, jika tidak ada, default-nya true (hanya wifi)
      downloadHanyaWifi = prefs.getBool('downloadHanyaWifi') ?? true;
    }

    // Simpan pengaturan baru
    Future<void> saveSettings(bool value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('downloadHanyaWifi', value);
    }

    // Tampilkan Bottom Sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // Gunakan StatefulBuilder agar UI di dalam sheet bisa di-update
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Panggil loadSettings saat pertama kali sheet dibangun
            loadSettings().then((_) {
              // Perbarui UI setelah pengaturan dimuat
              // Pengecekan `if (mounted)` tidak diperlukan di sini
              setState(() {});
            });

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // --- GARIS DRAG HANDLE ---
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16), // Jarak antara garis dan menu
                  // Opsi "Hanya Wifi"
                  ListTile(
                    leading: const Icon(Icons.wifi, color: Colors.white70),
                    title: const Text('Hanya Wifi'),
                    subtitle: const Text(
                      'Download hanya menggunakan koneksi Wifi',
                      style: TextStyle(color: Colors.white54),
                    ),
                    trailing: Switch(
                      value: downloadHanyaWifi,
                      activeThumbColor: const Color(
                        0xFF8A60FF,
                      ), // Warna toggle aktif
                      onChanged: (value) {
                        setState(() {
                          downloadHanyaWifi =
                              true; // Jika ini diubah, nilainya pasti true
                        });
                        saveSettings(true);
                      },
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  // Opsi "Data Seluler"
                  ListTile(
                    leading: const Icon(
                      Icons.signal_cellular_alt,
                      color: Colors.white70,
                    ),
                    title: const Text('Download via Data Seluler'),
                    subtitle: const Text(
                      'Download dapat menggunakan koneksi Wifi & Data',
                      style: TextStyle(color: Colors.white54),
                    ),
                    trailing: Switch(
                      value: !downloadHanyaWifi, // Kebalikan dari "Hanya Wifi"
                      activeThumbColor: const Color(0xFF8A60FF),
                      onChanged: (value) {
                        setState(() {
                          downloadHanyaWifi =
                              false; // Jika ini diubah, nilainya pasti false
                        });
                        saveSettings(false);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPengaturanNotifikasiSheet(BuildContext context) {
    // Default state untuk setiap toggle
    bool notifSeriesUpdate = true;
    bool notifSeriesBaru = true;
    bool notifBalasanKomentar = true;

    // Muat pengaturan yang sudah tersimpan
    Future<void> loadSettings() async {
      final prefs = await SharedPreferences.getInstance();
      notifSeriesUpdate = prefs.getBool('notifSeriesUpdate') ?? true;
      notifSeriesBaru = prefs.getBool('notifSeriesBaru') ?? true;
      notifBalasanKomentar = prefs.getBool('notifBalasanKomentar') ?? true;
    }

    // Simpan pengaturan baru (reusable)
    Future<void> saveSetting(String key, bool value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Panggil loadSettings sekali saat sheet dibangun
            loadSettings().then((_) {
              // Pengecekan ini salah dan tidak diperlukan, langsung panggil setState
              setState(() {});
            });

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Garis Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Opsi "Series Update"
                  ListTile(
                    title: const Text('Series Update'),
                    trailing: Switch(
                      value: notifSeriesUpdate,
                      activeThumbColor: const Color(0xFF8A60FF),
                      onChanged: (value) {
                        setState(() => notifSeriesUpdate = value);
                        saveSetting('notifSeriesUpdate', value);
                      },
                    ),
                  ),
                  // Opsi "Series Baru"
                  ListTile(
                    title: const Text('Series Baru'),
                    trailing: Switch(
                      value: notifSeriesBaru,
                      activeThumbColor: const Color(0xFF8A60FF),
                      onChanged: (value) {
                        setState(() => notifSeriesBaru = value);
                        saveSetting('notifSeriesBaru', value);
                      },
                    ),
                  ),
                  // Opsi "Balasan Komentar"
                  ListTile(
                    title: const Text('Balasan Komentar'),
                    trailing: Switch(
                      value: notifBalasanKomentar,
                      activeThumbColor: const Color(0xFF8A60FF),
                      onChanged: (value) {
                        setState(() => notifBalasanKomentar = value);
                        saveSetting('notifBalasanKomentar', value);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPengaturanPlayerSheet(BuildContext context) {
    // Variabel untuk menampung pilihan kualitas saat ini
    String kualitasSaatIni = '1080p'; // Default

    // Muat pengaturan kualitas yang sudah tersimpan
    Future<void> loadSettings() async {
      final prefs = await SharedPreferences.getInstance();
      kualitasSaatIni = prefs.getString('kualitasStreaming') ?? '1080p';
    }

    // Simpan pengaturan kualitas yang baru
    Future<void> saveSettings(String newQuality) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kualitasStreaming', newQuality);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Panggil loadSettings sekali saat sheet dibangun
            loadSettings().then((_) => setState(() {}));

            // Helper widget untuk membuat tombol kualitas
            Widget buildQualityChip(String label) {
              final bool isActive = kualitasSaatIni == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => kualitasSaatIni = label);
                    saveSettings(label);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? const Color(0xFF8A60FF)
                        : Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(label),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Garis Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Judul "Kualitas Streaming"
                  const Text(
                    'Kualitas Streaming',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Barisan tombol kualitas
                  Row(
                    children: [
                      buildQualityChip('360p'),
                      buildQualityChip('480p'),
                      buildQualityChip('720p'),
                      buildQualityChip('1080p'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Judul "Forward Player"
                  const Text(
                    'Forward Player',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Tombol Aksi "Forward Player"
                  ElevatedButton.icon(
                    onPressed: () {
                      // Tutup bottom sheet saat ini sebelum membuka dialog baru
                      Navigator.of(context).pop();
                      // Panggil fungsi untuk menampilkan dialog forward player
                      _showForwardPlayerDialog(context);
                    },
                    icon: const Icon(Icons.replay_circle_filled_outlined),
                    label: const Text('Forward Player'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showForwardPlayerDialog(BuildContext context) {
    int durasiSaatIni = 10; // Default 10 detik

    // Muat pengaturan durasi yang sudah tersimpan
    Future<void> loadSettings() async {
      final prefs = await SharedPreferences.getInstance();
      durasiSaatIni = prefs.getInt('forwardPlayerDuration') ?? 10;
    }

    // Simpan pengaturan durasi yang baru
    Future<void> saveSettings(int newDuration) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('forwardPlayerDuration', newDuration);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Gunakan StatefulBuilder agar pilihan radio button bisa di-update
        return StatefulBuilder(
          builder: (context, setState) {
            // Muat pengaturan saat dialog pertama kali dibangun
            loadSettings().then((_) => setState(() {}));

            // Helper untuk membuat setiap baris pilihan
            Widget buildRadioOption(String title, int value) {
              return RadioListTile<int>(
                title: Text(title),
                value: value,
                groupValue: durasiSaatIni,
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() => durasiSaatIni = newValue);
                    saveSettings(newValue);
                    // Langsung tutup dialog setelah memilih
                    Navigator.of(context).pop();
                  }
                },
                activeColor: const Color(0xFF8A60FF),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              backgroundColor: Colors.grey[850],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Forward Player',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildRadioOption(
                      'Default',
                      10,
                    ), // Asumsi default adalah 10 detik
                    buildRadioOption('5 Detik', 5),
                    buildRadioOption('10 Detik', 10),
                    buildRadioOption('30 Detik', 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHapusCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.grey[850],
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ikon Tanda Seru
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.red,
                  child: Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),

                // Judul
                const Text(
                  'Konfirmasi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Pesan
                const Text(
                  'Apakah Anda Yakin Menghapus Semua Chace Aplikasi?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),

                // Tombol "Yakin" (dengan gradasi)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // HANYA menutup dialog, tidak ada aksi lain
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8A60FF), Colors.indigo],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: 50,
                        child: const Text('Yakin'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol "Batalkan"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cukup tutup dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batalkan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Grup Pengaturan Aplikasi ---
          const Text(
            'Pengaturan Aplikasi',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            ikon: Icons.download_outlined,
            teks: 'Pengaturan Download',
            onTap: () {
              // Panggil fungsi untuk menampilkan popup
              _showPengaturanDownloadSheet(context);
            },
          ),
          _buildMenuItem(
            ikon: Icons.notifications_outlined,
            teks: 'Pengaturan Notifikasi',
            onTap: () {
              // Panggil fungsi untuk menampilkan popup notifikasi
              _showPengaturanNotifikasiSheet(context);
            },
          ),
          _buildMenuItem(
            ikon: Icons.play_circle_outline,
            teks: 'Pengaturan Player',
            onTap: () {
              // Panggil fungsi untuk menampilkan popup pengaturan player
              _showPengaturanPlayerSheet(context);
            },
          ),
          _buildMenuItem(
            ikon: Icons.delete_outline,
            teks: 'Hapus Cache',
            onTap: () {
              // Panggil fungsi untuk menampilkan dialog konfirmasi
              _showHapusCacheDialog(context);
            },
          ),
          const SizedBox(height: 30),

          // --- Grup Tentang Aplikasi ---
          const Text(
            'Tentang Aplikasi',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildMenuItem(
            ikon: Icons.info_outline,
            teks: 'Kebijakan Privasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            ikon: Icons.description_outlined,
            teks: 'Syarat dan Ketentuan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsAndConditionsPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            ikon: Icons.email_outlined,
            teks: 'Kontak Kami',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactUsPage()),
              );
            },
          ),
          _buildMenuItem(
            ikon: Icons.info_outline,
            teks: 'Versi Aplikasi',
            onTap: () {},
          ),
          const SizedBox(height: 30),

          // --- Tombol Logout ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () => _logout(context), // Panggil fungsi logout
          ),
        ],
      ),
    );
  }

  // Helper widget untuk membuat setiap item menu
  Widget _buildMenuItem({
    required IconData ikon,
    required String teks,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(ikon),
      title: Text(teks),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
