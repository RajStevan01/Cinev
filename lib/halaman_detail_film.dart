import 'package:aplikasi_mobile/models/serial_tv.dart';
import 'package:aplikasi_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/models/episode.dart';
import 'package:aplikasi_mobile/halaman_player.dart';
import 'package:aplikasi_mobile/halaman_pemutar_video.dart'; // Tambahan untuk player lokal
import 'package:aplikasi_mobile/services/database_helper.dart'; // Tambahkan import database lokal
import 'package:aplikasi_mobile/services/notification_service.dart'; // Tambahan import
import 'package:firebase_auth/firebase_auth.dart'; // Tambahan untuk ambil UID

class HalamanDetailFilm extends StatefulWidget {
  final SerialTv serial;

  const HalamanDetailFilm({super.key, required this.serial});

  @override
  State<HalamanDetailFilm> createState() => _HalamanDetailFilmState();
}

class _HalamanDetailFilmState extends State<HalamanDetailFilm> {
  late Future<SerialTv> _detailSerialTv;
  final String? _userUid = FirebaseAuth.instance.currentUser?.uid; // Ambil UID user yang login
  final ApiService _apiService = ApiService();
  bool _apakahSinopsisDiperluas = false;
  Future<List<Episode>>? _daftarEpisodeFuture;
  // int _seasonTerpilih = 1; // <-- DIHAPUS
  int _episodeTerpilih = 1;
  bool _apakahDiFavorite = false;

  void _initStateLogic() {
    _cekStatusFavorite();
    if (widget.serial.isLokal) {
      // Jika film lokal, gunakan data dari objek yang sudah ada (tidak perlu fetch API detail)
      _detailSerialTv = Future.value(widget.serial);
      // Dummy 1 episode untuk film lokal (karena biasanya 1 full movie)
      _daftarEpisodeFuture = Future.value([
        Episode(
          nama: 'Full Movie',
          ringkasan: widget.serial.ringkasan,
          nomorEpisode: 1,
          pathGambar: widget.serial.pathLatar,
        )
      ]);
    } else {
      // Logika lama TMDB
      _detailSerialTv = _apiService.ambilDetailSerialTv(widget.serial.id);
      _detailSerialTv.then((detail) {
        if (mounted) {
          setState(() {
            _daftarEpisodeFuture = _apiService.ambilDaftarEpisode(widget.serial.id, 1);
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initStateLogic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background color dasar
      backgroundColor: const Color(0xFF1C1C27),
      body: FutureBuilder<SerialTv>(
        future: _detailSerialTv,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final detailSerial = snapshot.data!;
            return _buildDetailContent(detailSerial);
          }
          return const Center(child: Text('Data tidak ditemukan'));
        },
      ),
    );
  }

  void _cekStatusFavorite() async {
    if (_userUid == null) return; // Cegah error kalau belum login
    // Mengecek ke API MySQL
    final isExist = await DatabaseHelper.instance.cekFavorite(widget.serial.id, _userUid);
    if (mounted) {
      setState(() {
        _apakahDiFavorite = isExist;
      });
    }
  }

  void _tambahKeFavorite() async {
    if (_userUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu untuk menyimpan favorit')),
      );
      return;
    }

    // Menyiapkan data untuk dikirim ke API MySQL
    final data = {
      'id': widget.serial.id,
      'user_uid': _userUid, 
      'nama': widget.serial.nama,
      'pathPoster': widget.serial.pathPoster,
      'tanggalDitambahkan': DateTime.now().toIso8601String(), // Kembalikan waktu lokal HP
    };
    
    // TANGKAP HASILNYA (1 JIKA SUKSES, 0 JIKA GAGAL)
    int hasil = await DatabaseHelper.instance.tambahKeFavorite(data);

    if (hasil == 1) {
      // Hanya jalankan ini JIKA data BENAR-BENAR MASUK ke MySQL
      await NotificationService().simpanNotifKeLonceng(
        kategori: 'favorite',
        judul: 'Favorite Baru',
        pesan: '${widget.serial.nama} berhasil ditambahkan ke daftar favoritmu.',
      );

      if (mounted) {
        setState(() {
          _apakahDiFavorite = true; // Tombol baru boleh jadi merah
        });
      }
    } else {
      // Jika gagal masuk MySQL, tampilkan pesan error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan ke server! Periksa koneksi.')),
        );
      }
    }
  }

  void _hapusDariFavorite() async {
    if (_userUid == null) return;
    // Menghapus data dari MySQL
    await DatabaseHelper.instance.hapusDariFavorite(widget.serial.id, _userUid);
    if (mounted) {
      setState(() {
        _apakahDiFavorite = false;
      });
    }
  }

  // --- FUNGSI _gantiSeason DIHAPUS ---

  void _putarTrailer(int idSerial, String namaSerial, int nomorEpisode) async {
    // --- LOGIKA BARU UNTUK FILM LOKAL ---
    if (widget.serial.isLokal && widget.serial.urlVideoLokal != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HalamanPemutarVideo(
            pathVideo: widget.serial.urlVideoLokal!,
            judul: widget.serial.nama,
            idFilm: widget.serial.id,
            progressSeconds: widget.serial.progressSeconds,
          ),
        ),
      );
      return; // Berhenti di sini, jangan lanjut ke YouTube
    }

    // --- LOGIKA LAMA UNTUK TMDB (YOUTUBE) ---
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final youtubeKey = await _apiService.ambilLinkTrailer(idSerial);
      print('HASIL DARI API (YOUTUBE KEY): $youtubeKey');
      Navigator.of(context).pop(); // Tutup dialog loading

      if (youtubeKey != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HalamanPlayer(
              youtubeKey: youtubeKey,
              namaSerial: namaSerial,
              nomorEpisode: nomorEpisode,
              idFilm: widget.serial.id,
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildDetailContent(SerialTv detailSerial) {
    return Stack(
      children: [
        // --- KONTEN YANG BISA DI-SCROLL ---
        CustomScrollView(
          slivers: [
            // Spacer seukuran header kustom
            SliverToBoxAdapter(
              child: SizedBox(
                height: 380, // Sesuaikan tinggi header
              ),
            ),

            // --- Bagian Konten di Bawah Gambar ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- BARIS JUDUL DAN TOMBOL FAVORIT ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul
                        Expanded(
                          child: Text(
                            detailSerial.nama,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Tombol Favorit (PINDAH KE SINI)
                        IconButton(
                          onPressed: () {
                            if (_apakahDiFavorite) {
                              _hapusDariFavorite();
                            } else {
                              _tambahKeFavorite();
                            }
                          },
                          icon: Icon(
                            _apakahDiFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _apakahDiFavorite ? Colors.red : Colors.white,
                            size: 32, // Ukuran disamakan dikit
                          ),
                        ),
                      ],
                    ),
                    // --- AKHIR BARIS JUDUL ---

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          detailSerial.tanggalRilisPertama ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${detailSerial.durasiEpisode ?? 'N/A'} menit',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      children:
                          detailSerial.genre?.map((g) {
                            return Chip(
                              label: Text(g['name']),
                              backgroundColor: Colors.grey[850],
                            );
                          }).toList() ??
                          [],
                    ),
                    const SizedBox(height: 20),

                    // --- SINOPSIS ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detailSerial.ringkasan,
                          maxLines: _apakahSinopsisDiperluas ? null : 10,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _apakahSinopsisDiperluas =
                                  !_apakahSinopsisDiperluas;
                            });
                          },
                          child: Text(
                            _apakahSinopsisDiperluas
                                ? 'Lebih Sedikit'
                                : 'Selengkapnya',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- SECTION EPISODE (KODE BARU) ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Episode',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- Tombol Pilihan Season DIHAPUS ---

                        // --- Daftar Episode (GRID 5 KOLOM) ---
                        FutureBuilder<List<Episode>>(
                          future: _daftarEpisodeFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }
                            if (snapshot.hasData) {
                              final daftarEpisode = snapshot.data!;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      5, // Jumlah kolom
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1 / 1,
                                ),
                                itemCount: daftarEpisode.length,
                                itemBuilder: (context, index) {
                                  final episode = daftarEpisode[index];
                                  final int nomorEpisode = episode.nomorEpisode;

                                  return ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _episodeTerpilih = nomorEpisode;
                                      });
                                      _putarTrailer(
                                        widget.serial.id,
                                        widget.serial.nama,
                                        nomorEpisode,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _episodeTerpilih == nomorEpisode
                                              ? Colors.white
                                              : Colors.grey[850],
                                      foregroundColor:
                                          _episodeTerpilih == nomorEpisode
                                              ? Colors.black
                                              : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      nomorEpisode.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // --- HEADER KUSTOM (NUMPUK DI ATAS) ---
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 380, // Tinggi header
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gambar Background
                Image.network(
                  detailSerial.pathLatar ?? detailSerial.pathPoster,
                  fit: BoxFit.cover,
                ),
                // Gradien Hitam
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black54, // Sedikit gelap di atas
                        Colors.transparent,
                        Color(0xFF1C1C27) // Hitam pekat di bawah
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Poster di Tengah Bawah
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        detailSerial.pathPoster,
                        width: 140,
                        height: 210,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Tombol Back dan Favorit
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween, <-- HAPUS INI
                    children: [
                      // Tombol Back
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      // <-- Tombol Favorit SUDAH DIHAPUS DARI SINI
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
