// lib/halaman_player.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aplikasi_mobile/services/download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Tambahan untuk memantau proses di belakang layar
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aplikasi_mobile/models/review.dart';
import 'package:aplikasi_mobile/services/notification_service.dart'; // Dikembalikan
import 'package:aplikasi_mobile/services/database_helper.dart'; // Dikembalikan
import 'package:aplikasi_mobile/halaman_pemutar_video.dart';
import 'package:video_player/video_player.dart';

class HalamanPlayer extends StatefulWidget {
  final String youtubeKey;
  final String namaSerial;
  final int nomorEpisode;
  final int idFilm;
  final bool isLokal;
  final String? urlVideoLokal;
  final int? progressSeconds;

  const HalamanPlayer({
    super.key,
    required this.youtubeKey,
    required this.namaSerial,
    required this.nomorEpisode,
    required this.idFilm,
    this.isLokal = false,
    this.urlVideoLokal,
    this.progressSeconds,
  });

  @override
  State<HalamanPlayer> createState() => _HalamanPlayerState();
}

class _HalamanPlayerState extends State<HalamanPlayer> {
  WebViewController? _webController;
  VideoPlayerController? _videoController;
  bool _isPlayerReady = false;

  final DownloadService _downloadService = DownloadService();
  late String _taskId; // ID unik untuk setiap video
  String _kualitasPilihan = '1080p';
  StreamSubscription? _downloadSubscription;
  bool _notifTerkirim =
      false; // Kunci gembok agar notif tidak muncul berkali-kali

  bool _isLiked = false;
  int _totalLikes = 0;
  List<Review> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  
  late Future<List<BannerModel>> _daftarBannerPlayer;

  @override
  void initState() {
    super.initState();
    _taskId = '${widget.namaSerial}_ep${widget.nomorEpisode}';
    
    if (widget.isLokal && widget.urlVideoLokal != null) {
      _initLocalPlayer();
    } else {
      _loadSettingsAndInitWebView();
    }

    // --- TAMBAHAN BARU: Pasang CCTV untuk memantau stream download ---
    _downloadSubscription = _downloadService.progressStream.listen((tasks) {
      final task = tasks[_taskId];

      // Jika statusnya selesai (completed) DAN notif belum pernah dikirim
      if (task != null &&
          task.status == DownloadStatus.completed &&
          !_notifTerkirim) {
        _notifTerkirim = true; // Kunci pintunya agar tidak berulang

        // 1. Munculkan Notifikasi Pop-up berbunyi dari atas layar
        NotificationService().tampilkanNotifikasiDownload(
          namaFilm: widget.namaSerial,
        );

        // 2. Simpan sejarahnya ke Database Lonceng secara diam-diam
        NotificationService().simpanNotifKeLonceng(
          kategori: 'download',
          judul: 'Download Selesai ✅',
          pesan:
              'Film ${widget.namaSerial} Episode ${widget.nomorEpisode} berhasil diunduh dan siap ditonton offline!',
        );
      }
    });

    // Simpan history ke database (karena Youtube, kita simpan detik 0)
    _simpanRiwayatKeDatabase();

    _fetchLikeStatus();
    _fetchReviews();
    
    _daftarBannerPlayer = DatabaseHelper.instance.ambilDaftarBanner().then((data) => data['player'] ?? []);
  }

  Future<void> _fetchLikeStatus() async {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid != null) {
      final res = await DatabaseHelper.instance.cekStatusLike(userUid, widget.idFilm);
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
      // Optimsitik UI update
      setState(() {
        _isLiked = !_isLiked;
        _totalLikes += _isLiked ? 1 : -1;
      });
      final res = await DatabaseHelper.instance.toggleLike(userUid, widget.idFilm);
      if (res['status'] != 'success') {
        // Rollback jika gagal
        if (mounted) {
          setState(() {
            _isLiked = !_isLiked;
            _totalLikes += _isLiked ? 1 : -1;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyukai film')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu')));
    }
  }

  Future<void> _fetchReviews() async {
    final res = await DatabaseHelper.instance.ambilReview(widget.idFilm);
    if (mounted && res['status'] == 'success') {
      setState(() {
        _reviews = res['reviews'];
        _averageRating = (res['average_rating'] as num).toDouble();
        _totalReviews = res['total_reviews'];
      });
    }
  }

  Future<void> _simpanRiwayatKeDatabase() async {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid != null) {
      // Kita pakai durasi dummy karena tidak bisa tracking iframe
      await DatabaseHelper.instance.simpanHistory(userUid, widget.idFilm, 0, 100); 
    }
  }

  @override
  void dispose() {
    // CCTV wajib dimatikan saat pindah halaman agar memori HP tidak bocor (Memory Leak)
    _downloadSubscription?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndInitWebView() async {
    // Muat pengaturan kualitas secara asinkron
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _kualitasPilihan = prefs.getString('kualitasStreaming') ?? '1080p';
      });
    }

    final videoUrl = 'https://www.youtube.com/embed/${widget.youtubeKey}?autoplay=1&fs=1';
    
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(videoUrl))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isPlayerReady = true;
              });
            }
          },
        ),
      );
  }

  Future<void> _initLocalPlayer() async {
    // Karena video kita diakses melalui URL lokal backend (contoh: http://192.168.x.x/cinev_api/uploads/video.mp4),
    // kita selalu menggunakan networkUrl.
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.urlVideoLokal!));

    await _videoController!.initialize();
    if (mounted) {
      setState(() {
        _isPlayerReady = true;
      });
      if (widget.progressSeconds != null && widget.progressSeconds! > 0) {
        _videoController!.seekTo(Duration(seconds: widget.progressSeconds!));
      }
      _videoController!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _isPlayerReady
                  ? (widget.isLokal && _videoController != null
                      ? Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            VideoPlayer(_videoController!),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                                });
                              },
                              child: Center(
                                child: Icon(
                                  _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  size: 60.0,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: VideoProgressIndicator(_videoController!, allowScrubbing: true, padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10)),
                            ),
                            Positioned(
                              bottom: 15,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
                                onPressed: () async {
                                  // Pause video lokal yang kecil
                                  _videoController!.pause();
                                  // Navigasi ke halaman fullscreen
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HalamanPemutarVideo(
                                        pathVideo: widget.urlVideoLokal!,
                                        judul: widget.namaSerial,
                                        idFilm: widget.idFilm,
                                        progressSeconds: _videoController!.value.position.inSeconds,
                                      ),
                                    ),
                                  );
                                  // Ketika kembali dari fullscreen, jangan lanjutkan memutar secara otomatis.
                                  // Tapi jika ingin dilanjutkan, atau setel ke posisi baru (progress di sync jika halaman lain menyimpannya di DB, atau biarkan pengguna nge-play manual)
                                },
                              ),
                            ),
                          ],
                        )
                      : WebViewWidget(controller: _webController!))
                  : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.namaSerial,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40, // Memberi tinggi tetap untuk list horizontal
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Tombol Like & Dislike menyatu
                        Container(
                          margin: const EdgeInsets.only(right: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _toggleLike,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(_isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, size: 18, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        _totalLikes >= 1000 ? '${(_totalLikes / 1000).toStringAsFixed(1)}k' : _totalLikes.toString(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(width: 1, height: 20, color: Colors.white30), // Garis pemisah
                              InkWell(
                                onTap: () {}, // Logika dislike belum ada
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.thumb_down_alt_outlined, size: 18, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text('3k', style: TextStyle(color: Colors.white)), // Tampilan statis sesuai Figma
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildTombolAksi(
                          ikon: Icons.play_circle_fill_outlined,
                          teks: '$_kualitasPilihan Quality',
                        ),

                        // --- GANTI BLOK PADDING SEBELUMNYA DENGAN STREAMBUILDER INI ---
                        StreamBuilder<Map<String, DownloadTask>>(
                          stream: _downloadService.progressStream,
                          initialData: {}, // Data awal kosong
                          builder: (context, snapshot) {
                            final tasks = snapshot.data ?? {};
                            final task =
                                tasks[_taskId]; // Cari tugas yang sesuai dengan ID video ini

                            String text = 'Download';
                            IconData icon = Icons.download_outlined;
                            Color buttonColor = Colors.grey[850]!;
                            VoidCallback? onPressed = () {
                              // Perintahkan DownloadService untuk memulai download
                              _downloadService.startDownload(
                                _taskId,
                                'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
                              );
                            };

                            // Logika untuk mengubah tampilan tombol berdasarkan status
                            if (task != null) {
                              switch (task.status) {
                                case DownloadStatus.downloading:
                                  text =
                                      '${(task.progress * 100).toStringAsFixed(0)}%';
                                  onPressed =
                                      null; // Tombol tidak bisa ditekan saat loading
                                  break;
                                case DownloadStatus.completed:
                                  text = 'Downloaded';
                                  icon = Icons.check_circle_outline;
                                  buttonColor =
                                      Colors.green; // Warna hijau jika selesai
                                  onPressed = null;
                                  break;
                                case DownloadStatus.error:
                                  text = 'Retry';
                                  icon = Icons.error_outline;
                                  break;
                                default:
                                  break;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton.icon(
                                onPressed: onPressed,
                                icon: task?.status == DownloadStatus.downloading
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          value: task!.progress,
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Icon(icon, size: 18),
                                label: Text(text),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // ----------------------------------------------------------------
                        _buildTombolAksi(
                          ikon: Icons.share_outlined,
                          teks: 'Share',
                        ),
                        _buildTombolAksi(
                          ikon: Icons.flag_outlined,
                          teks: 'Report',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Episode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.nomorEpisode.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<List<BannerModel>>(
                    future: _daftarBannerPlayer,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final banner = snapshot.data!.first; // Ambil banner pertama untuk player
                        return GestureDetector(
                          onTap: () async {
                            if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) {
                              final uri = Uri.parse(banner.linkUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              banner.pathGambar,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 100,
                                color: Colors.grey[800],
                                child: const Icon(Icons.error, color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink(); // Sembunyikan jika tidak ada banner
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                            ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                            : null,
                        child: FirebaseAuth.instance.currentUser?.photoURL == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showReviewBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'Tambahkan komentar anda',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildReviewsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return const Text('Belum ada ulasan untuk film ini.', style: TextStyle(color: Colors.white70));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ulasan ($_totalReviews)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._reviews.map((review) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: review.photoUrl.isNotEmpty ? NetworkImage(review.photoUrl) : null,
                    child: review.photoUrl.isEmpty ? const Icon(Icons.person) : null,
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
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              review.waktuDibuat.split(' ')[0],
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(review.komentar, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
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
                          index < selectedRating ? Icons.star : Icons.star_border,
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih rating')));
                          return;
                        }
                        final userUid = FirebaseAuth.instance.currentUser?.uid;
                        if (userUid == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu')));
                          return;
                        }

                        // Tampilkan loading dialog atau ubah state, untuk kesederhanaan kita langsung pop jika sukses
                        final res = await DatabaseHelper.instance.simpanReview(
                          userUid,
                          widget.idFilm,
                          selectedRating,
                          komentarController.text,
                        );

                        if (res['status'] == 'success') {
                          Navigator.pop(context);
                          _fetchReviews(); // Refresh ulasan
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan ulasan')));
                        }
                      },
                      child: const Text('Kirim', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildTombolAksi({required IconData ikon, required String teks, VoidCallback? onPressed}) {
    return Padding(
      // Memberi jarak antar tombol
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed ?? () {},
        icon: Icon(ikon, size: 18), // Ukuran ikon di dalam tombol
        label: Text(teks),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[850], // Warna background tombol
          foregroundColor: Colors.white, // Warna teks & ikon
          shape: const StadiumBorder(), // Bentuk pil otomatis
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
