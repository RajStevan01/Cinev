// lib/halaman_player.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aplikasi_mobile/services/download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Tambahan untuk memantau proses di belakang layar
import 'package:aplikasi_mobile/services/notification_service.dart'; // Tambahan untuk memanggil notif
import 'package:aplikasi_mobile/services/database_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HalamanPlayer extends StatefulWidget {
  final String youtubeKey;
  final String namaSerial;
  final int nomorEpisode;
  final int idFilm;

  const HalamanPlayer({
    super.key,
    required this.youtubeKey,
    required this.namaSerial,
    required this.nomorEpisode,
    required this.idFilm,
  });

  @override
  State<HalamanPlayer> createState() => _HalamanPlayerState();
}

class _HalamanPlayerState extends State<HalamanPlayer> {
  late final WebViewController _controller;
  bool _isPlayerReady = false;

  final DownloadService _downloadService = DownloadService();
  late String _taskId; // ID unik untuk setiap video
  String _kualitasPilihan = '1080p';
  StreamSubscription? _downloadSubscription;
  bool _notifTerkirim =
      false; // Kunci gembok agar notif tidak muncul berkali-kali

  @override
  void initState() {
    super.initState();
    _taskId = '${widget.namaSerial}_ep${widget.nomorEpisode}';
    _loadSettingsAndInitWebView();

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
    
    _controller = WebViewController()
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
                  ? WebViewWidget(controller: _controller)
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
                        _buildTombolAksi(
                          ikon: Icons.thumb_up_alt_outlined,
                          teks: '1.6k',
                        ),
                        _buildTombolAksi(
                          ikon: Icons.thumb_down_alt_outlined,
                          teks: '3k',
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
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(widget.nomorEpisode.toString()),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/iklan_banner.png'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTombolAksi({required IconData ikon, required String teks}) {
    return Padding(
      // Memberi jarak antar tombol
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Tambahkan fungsionalitas untuk setiap tombol nanti
        },
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
