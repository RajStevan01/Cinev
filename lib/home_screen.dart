// lib/home_screen.dart (VERSI BARU YANG LEBIH RAMPING)

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/halaman_pencarian.dart';
import 'package:aplikasi_mobile/models/serial_tv.dart';
import 'package:aplikasi_mobile/services/api_service.dart';
import 'package:aplikasi_mobile/halaman_detail_film.dart';
import 'package:aplikasi_mobile/halaman_lihat_semua.dart';
import 'package:aplikasi_mobile/halaman_notifikasi.dart'; // Import halaman notifikasi
import 'package:aplikasi_mobile/services/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aplikasi_mobile/halaman_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<SerialTv>> _serialTvRatingTertinggi;
  late Future<List<SerialTv>> _serialTvPopuler;
  late Future<List<SerialTv>> _serialTvRiwayat; // Tambahan untuk history
  late PageController _pageController;
  Timer? _timer;
  int _halamanSaatIni = 0;
  late Future<List<BannerModel>> _daftarBanner;
  int _bannerCount = 0;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data film dari API (Digabung Lokal + TMDB)
    _serialTvRatingTertinggi = Future.wait([
      _apiService.ambilSerialTvLokal(), // Panggil API Lokal
      _apiService.ambilDaftarSerialTv('rating_tertinggi') // Panggil API TMDB
    ]).then((List<List<SerialTv>> results) {
      // Menggabungkan list Lokal dan TMDB (Lokal ditaruh di awal)
      return [...results[0], ...results[1]];
    });

    _serialTvPopuler = _apiService.ambilDaftarSerialTv('populer');
    
    // Ambil riwayat tontonan
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid != null) {
      _serialTvRiwayat = DatabaseHelper.instance.ambilRiwayatTontonan(userUid).then((listData) {
        return listData.map((json) => SerialTv.dariJsonLokal(json)).toList();
      });
    } else {
    _serialTvRiwayat = Future.value([]); // Kosong jika belum login
    }

    _daftarBanner = DatabaseHelper.instance.ambilDaftarBanner().then((data) => data['home'] ?? []);

    // Inisialisasi PageController dan Timer untuk banner
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_bannerCount > 0) {
        if (_halamanSaatIni < _bannerCount - 1) {
          _halamanSaatIni++;
        } else {
          _halamanSaatIni = 0;
        }

        // Pastikan controller masih ada sebelum dianimasikan
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _halamanSaatIni,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeIn,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    // Halaman ini TIDAK lagi memiliki Scaffold atau BottomNavigationBar
    return Material(
      child: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                StreamBuilder<User?>(
                  // Menggunakan userChanges() agar stream langsung dari Auth
                  stream: FirebaseAuth.instance.userChanges(),
                  builder: (context, snapshot) {
                    String namaPengguna = 'Kamu'; // Nama default
                    String? urlFotoProfil;

                    if (snapshot.hasData && snapshot.data != null) {
                      final user = snapshot.data!;
                      // Mengambil nama dari displayName bawaan Firebase Auth
                      namaPengguna = user.displayName ?? 'Kamu';
                      urlFotoProfil = user.photoURL;
                    }

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: urlFotoProfil != null
                              ? NetworkImage(urlFotoProfil)
                              : null,
                          child: urlFotoProfil == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, $namaPengguna!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Nonton Film Favorit Kamu!',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, size: 28),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HalamanNotifikasi()),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- SEARCH BAR ---
                GestureDetector(
                  onTap: () {
                    // Navigasi ke HalamanPencarian saat search bar di-tap
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HalamanPencarian(),
                      ),
                    );
                  },
                  child: AbsorbPointer(
                    // Mencegah keyboard muncul di halaman home
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari Film',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[850],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- BANNER CAROUSEL ---
                SizedBox(
                  height: 150.0,
                  width: double.infinity,
                  child: FutureBuilder<List<BannerModel>>(
                    future: _daftarBanner,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        // Tampilkan banner dummy/kosong jika gagal atau kosong
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text('Tidak ada banner', style: TextStyle(color: Colors.white))),
                        );
                      }

                      final banners = snapshot.data!;
                      // Simpan jumlah banner untuk timer
                      if (_bannerCount != banners.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _bannerCount = banners.length;
                            });
                          }
                        });
                      }

                      return PageView.builder(
                        controller: _pageController,
                        itemCount: banners.length,
                        itemBuilder: (context, index) {
                          final banner = banners[index];
                          return GestureDetector(
                            onTap: () async {
                              if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) {
                                final uri = Uri.parse(banner.linkUrl!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  banner.pathGambar,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.error, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // --- SECTION LANJUTKAN MENONTON (RIWAYAT) ---
                FutureBuilder<List<SerialTv>>(
                  future: _serialTvRiwayat,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMoviesSection(
                            title: 'Lanjutkan Menonton',
                            future: _serialTvRiwayat,
                            isHorizontal: true,
                            isRiwayat: true,
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                    return const SizedBox.shrink(); // Sembunyikan jika kosong
                  },
                ),

                // --- SECTION RATING TERTINGGI (HORIZONTAL) ---
                _buildMoviesSection(
                  title: 'Rating Tertinggi',
                  future: _serialTvRatingTertinggi,
                  isHorizontal: true,
                ),
                const SizedBox(height: 24),

                // --- SECTION POPULER (TERLARIS - GRID) ---
                _buildMoviesSection(
                  title: 'Terlaris',
                  future: _serialTvPopuler,
                  isHorizontal: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _langsungPutarLanjutan(SerialTv serial) async {
    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int nomorEpisode = 1; // Default
    String? urlVideoLokal;

    try {
      if (serial.isLokal) {
        // Coba ambil episode 1 untuk film lokal
        final episodes = await _apiService.ambilEpisodeLokal(serial.id);
        if (episodes.isNotEmpty) {
          final ep1 = episodes.first;
          nomorEpisode = ep1.episodeNumber;
          urlVideoLokal = ep1.videoUrl;
        }

        if (urlVideoLokal != null) {
          Navigator.of(context).pop(); // Tutup dialog loading
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HalamanPlayer(
                youtubeKey: '', // Kosongkan karena bukan dari youtube
                namaSerial: serial.nama,
                nomorEpisode: nomorEpisode,
                idFilm: serial.id,
                isLokal: true,
                urlVideoLokal: urlVideoLokal,
                progressSeconds: serial.progressSeconds,
              ),
            ),
          );
          return; // Berhenti di sini
        }
      }

      // --- LOGIKA TMDB (YOUTUBE) ---
      final youtubeKey = await _apiService.ambilLinkTrailer(serial.id);
      Navigator.of(context).pop(); // Tutup dialog loading

      if (youtubeKey != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HalamanPlayer(
              youtubeKey: youtubeKey,
              namaSerial: serial.nama,
              nomorEpisode: nomorEpisode,
              idFilm: serial.id,
              progressSeconds: serial.progressSeconds,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trailer untuk serial ini tidak ditemukan.'),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Tutup dialog loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat film: $e')),
      );
    }
  }

  // SEMUA FUNGSI HELPER (_buildMoviesSection, dll) TIDAK BERUBAH
  Widget _buildMoviesSection({
    required String title,
    required Future<List<SerialTv>> future,
    required bool isHorizontal,
    bool isRiwayat = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00F5FF),
              ),
            ),
            // Tombol "Lihat Semua" hanya akan muncul jika judul BUKAN "Terlaris"
            if (title != 'Terlaris')
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanLihatSemua(
                        judul: title, // Kirim judul section
                        futureDaftarSerial: future, // Kirim data filmnya
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(color: Color(0xFF00F5FF)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<SerialTv>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final daftarSerial = snapshot.data!;
              return isHorizontal
                  ? _buildHorizontalSerialList(daftarSerial, isRiwayat)
                  : _buildVerticalSerialGrid(daftarSerial);
            }
            return const Center(child: Text('Tidak ada film ditemukan'));
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalSerialList(List<SerialTv> daftarSerial, [bool isRiwayat = false]) {
    return SizedBox(
      height: 220, // Tambah height sedikit untuk progress bar
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: daftarSerial.length,
        itemBuilder: (context, index) {
          final serial = daftarSerial[index];
          return InkWell(
            onTap: () {
              if (isRiwayat) {
                _langsungPutarLanjutan(serial);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HalamanDetailFilm(serial: serial),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFF00F5FF),
                          width: 2.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.network(
                          serial.pathPoster,
                          height: 160,
                          width: 120,
                          fit: BoxFit.cover,
                          // ... (loadingBuilder)
                        ),
                      ),
                    ),
                    if (isRiwayat && serial.totalSeconds != null && serial.totalSeconds! > 0)
                      Container(
                        width: 120,
                        margin: const EdgeInsets.only(top: 4),
                        child: LinearProgressIndicator(
                          value: (serial.progressSeconds ?? 0) / serial.totalSeconds!,
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      serial.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // lalu ganti dengan kode ini:
  Widget _buildVerticalSerialGrid(List<SerialTv> daftarSerial) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2 / 3.5, // Kita kembalikan rasionya sedikit
      ),
      itemCount: daftarSerial.length,
      itemBuilder: (context, index) {
        final serial = daftarSerial[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HalamanDetailFilm(serial: serial),
              ),
            );
          },
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF00F5FF),
              width: 2.0,
            ),
          ),
          // ClipRRect untuk melengkungkan gambar di dalam border
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              26,
            ), // Sedikit lebih kecil dari border
            child: Image.network(
              serial.pathPoster,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[850],
                  child: const Icon(Icons.movie, color: Colors.white54),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[850],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
        ),
        );
      },
    );
  }
}
