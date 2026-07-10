import 'package:aplikasi_mobile/models/serial_tv.dart';
import 'package:aplikasi_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/models/episode.dart';
import 'package:aplikasi_mobile/halaman_player.dart';
import 'package:aplikasi_mobile/halaman_pemutar_video.dart'; // Tambahan untuk player lokal
import 'package:aplikasi_mobile/services/database_helper.dart'; // Tambahkan import database lokal
import 'package:aplikasi_mobile/services/notification_service.dart'; // Tambahan import
import 'package:firebase_auth/firebase_auth.dart'; // Tambahan untuk ambil UID
import 'package:aplikasi_mobile/models/review.dart';

class HalamanDetailFilm extends StatefulWidget {
  final SerialTv serial;

  const HalamanDetailFilm({super.key, required this.serial});

  @override
  State<HalamanDetailFilm> createState() => _HalamanDetailFilmState();
}

class _HalamanDetailFilmState extends State<HalamanDetailFilm> {
  late Future<SerialTv> _detailSerialTv;
  final String? _userUid =
      FirebaseAuth.instance.currentUser?.uid; // Ambil UID user yang login
  final ApiService _apiService = ApiService();
  bool _apakahSinopsisDiperluas = false;
  Future<List<Episode>>? _daftarEpisodeFuture;
  // int _seasonTerpilih = 1; // <-- DIHAPUS
  int _episodeTerpilih = 1;
  bool _apakahDiFavorite = false;

  bool _isLiked = false;
  int _totalLikes = 0;
  List<Review> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;

  void _initStateLogic() {
    _cekStatusFavorite();
    _fetchLikeStatus();
    _fetchReviews();
    if (widget.serial.isLokal) {
      // Jika film lokal, gunakan data dari objek yang sudah ada (tidak perlu fetch API detail)
      _detailSerialTv = Future.value(widget.serial);
      
      if (widget.serial.type == 'series') {
        // Fetch episode lokal
        _daftarEpisodeFuture = _apiService.ambilEpisodeLokal(widget.serial.id).then((episodes) {
          return episodes.map((ep) => Episode(
            nama: ep.title,
            ringkasan: '', // Episode lokal belum ada sinopsis terpisah
            nomorEpisode: ep.episodeNumber,
            pathGambar: widget.serial.pathLatar, // Pake backdrop series
            urlVideoLokal: ep.videoUrl,
          )).toList();
        });
      } else {
        // Dummy 1 episode untuk film lokal tipe movie
        _daftarEpisodeFuture = Future.value([
          Episode(
            nama: 'Full Movie',
            ringkasan: widget.serial.ringkasan,
            nomorEpisode: 1,
            pathGambar: widget.serial.pathLatar,
            urlVideoLokal: widget.serial.urlVideoLokal,
          ),
        ]);
      }
    } else {
      // Logika lama TMDB
      _detailSerialTv = _apiService.ambilDetailSerialTv(widget.serial.id);
      _detailSerialTv.then((detail) {
        if (mounted) {
          setState(() {
            _daftarEpisodeFuture = _apiService.ambilDaftarEpisode(
              widget.serial.id,
              1,
            );
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

  Future<void> _fetchLikeStatus() async {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid != null) {
      final res = await DatabaseHelper.instance.cekStatusLike(
        userUid,
        widget.serial.id,
      );
      if (mounted && res['status'] == 'success') {
        setState(() {
          _isLiked = res['is_liked'];
          _totalLikes = res['total_likes'];
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid != null) {
      setState(() {
        _isLiked = !_isLiked;
        _totalLikes += _isLiked ? 1 : -1;
      });
      final res = await DatabaseHelper.instance.toggleLike(
        userUid,
        widget.serial.id,
      );
      if (res['status'] != 'success') {
        if (mounted) {
          setState(() {
            _isLiked = !_isLiked;
            _totalLikes += _isLiked ? 1 : -1;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Gagal menyukai film')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
    }
  }

  Future<void> _fetchReviews() async {
    final res = await DatabaseHelper.instance.ambilReview(widget.serial.id);
    if (mounted && res['status'] == 'success') {
      setState(() {
        _reviews = res['reviews'];
        _averageRating = (res['average_rating'] as num).toDouble();
        _totalReviews = res['total_reviews'];
      });
    }
  }

  void _cekStatusFavorite() async {
    if (_userUid == null) return; // Cegah error kalau belum login
    // Mengecek ke API MySQL
    final isExist = await DatabaseHelper.instance.cekFavorite(
      widget.serial.id,
      _userUid,
    );
    if (mounted) {
      setState(() {
        _apakahDiFavorite = isExist;
      });
    }
  }

  void _tambahKeFavorite() async {
    if (_userUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan login terlebih dahulu untuk menyimpan favorit',
          ),
        ),
      );
      return;
    }

    // Menyiapkan data untuk dikirim ke API MySQL
    final data = {
      'id': widget.serial.id,
      'user_uid': _userUid,
      'nama': widget.serial.nama,
      'pathPoster': widget.serial.pathPoster,
      'tanggalDitambahkan': DateTime.now()
          .toIso8601String(), // Kembalikan waktu lokal HP
    };

    // TANGKAP HASILNYA (1 JIKA SUKSES, 0 JIKA GAGAL)
    int hasil = await DatabaseHelper.instance.tambahKeFavorite(data);

    if (hasil == 1) {
      // Hanya jalankan ini JIKA data BENAR-BENAR MASUK ke MySQL
      await NotificationService().simpanNotifKeLonceng(
        kategori: 'favorite',
        judul: 'Favorite Baru',
        pesan:
            '${widget.serial.nama} berhasil ditambahkan ke daftar favoritmu.',
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
          const SnackBar(
            content: Text('Gagal menyimpan ke server! Periksa koneksi.'),
          ),
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

  void _putarTrailer(int idSerial, String namaSerial, int nomorEpisode, {String? urlVideoLokal}) async {
    // --- LOGIKA BARU UNTUK FILM LOKAL ---
    if (widget.serial.isLokal && urlVideoLokal != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HalamanPlayer(
            youtubeKey: '', // Kosongkan karena bukan dari youtube
            namaSerial: widget.serial.nama,
            nomorEpisode: nomorEpisode,
            idFilm: widget.serial.id,
            isLokal: true,
            urlVideoLokal: urlVideoLokal,
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
    return SingleChildScrollView(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background hitam untuk semua konten
          Container(
            color: const Color(0xFF111111),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image
                Stack(
                  children: [
                    Image.network(
                      detailSerial.pathLatar ?? detailSerial.pathPoster,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                    ),
                    // Gradien transisi ke hitam
                    Container(
                      height: 280,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black54,
                            Colors.transparent,
                            Color(0xFF111111),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    // Tombol Back
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),

                // Area Poster (Overlap dari atas)
                const SizedBox(height: 140), // Ruang untuk poster overlap

                // Judul
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      detailSerial.nama,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Metadata (Tahun, Durasi)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      detailSerial.tanggalRilisPertama?.split('-')[0] ?? 'N/A',
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 24),
                    const Icon(Icons.access_time_filled, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${detailSerial.durasiEpisode ?? '-'} min',
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Genres (Grid Wrap)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      alignment: WrapAlignment.center,
                      children: detailSerial.genre?.map((g) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54, width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            g['name'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList() ?? [],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sinopsis
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    detailSerial.ringkasan,
                    maxLines: _apakahSinopsisDiperluas ? null : 4,
                    overflow: _apakahSinopsisDiperluas ? null : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol Selengkapnya
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _apakahSinopsisDiperluas = !_apakahSinopsisDiperluas;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _apakahSinopsisDiperluas ? 'Lebih Sedikit' : 'Selengkapnya',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Section Episode
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Episode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Episode List (Future Builder)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder<List<Episode>>(
                    future: _daftarEpisodeFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                      }
                      if (snapshot.hasData) {
                        final daftarEpisode = snapshot.data!;
                        return Wrap(
                          spacing: 12.0,
                          runSpacing: 12.0,
                          children: daftarEpisode.map((episode) {
                            final int nomorEpisode = episode.nomorEpisode;
                            final isSelected = _episodeTerpilih == nomorEpisode;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _episodeTerpilih = nomorEpisode;
                                });
                                _putarTrailer(
                                  widget.serial.id,
                                  widget.serial.nama,
                                  nomorEpisode,
                                  urlVideoLokal: episode.urlVideoLokal,
                                );
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  border: Border.all(color: isSelected ? Colors.white : Colors.white54),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  nomorEpisode.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          // Poster Absolut Overlap
          Positioned(
            top: 130, // Letaknya berada menumpuk background dan header
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  detailSerial.pathPoster,
                  width: 200,
                  height: 280,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Icon Heart Absolut Overlap
          Positioned(
            top: 240, // Letaknya berada di dekat background line (280) 
            right: 24,
            child: IconButton(
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
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTombolAksi({
    required IconData ikon,
    required String teks,
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed ?? () {},
        icon: Icon(ikon, size: 18),
        label: Text(teks),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return const Text(
        'Belum ada ulasan untuk film ini.',
        style: TextStyle(color: Colors.white70),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ulasan ($_totalReviews)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._reviews
            .map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: review.photoUrl.isNotEmpty
                          ? NetworkImage(review.photoUrl)
                          : null,
                      child: review.photoUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                review.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                review.waktuDibuat.split(' ')[0],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < review.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review.komentar,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  void _showReviewBottomSheet() {
    int selectedRating = 0;
    final TextEditingController komentarController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berikan Ulasan Anda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: komentarController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar...',
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (selectedRating == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Silakan pilih rating'),
                            ),
                          );
                          return;
                        }
                        final userUid = FirebaseAuth.instance.currentUser?.uid;
                        if (userUid == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Silakan login terlebih dahulu'),
                            ),
                          );
                          return;
                        }

                        final res = await DatabaseHelper.instance.simpanReview(
                          userUid,
                          widget.serial.id,
                          selectedRating,
                          komentarController.text,
                        );

                        if (res['status'] == 'success') {
                          Navigator.pop(context);
                          _fetchReviews(); // Refresh ulasan
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                res['message'] ?? 'Gagal menyimpan ulasan',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Kirim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
