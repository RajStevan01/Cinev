import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:aplikasi_mobile/services/database_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HalamanPemutarVideo extends StatefulWidget {
  final String pathVideo;
  final String judul;
  final int? idFilm; // Untuk riwayat
  final int? progressSeconds; // Untuk melanjutkan riwayat

  const HalamanPemutarVideo({
    super.key,
    required this.pathVideo,
    required this.judul,
    this.idFilm,
    this.progressSeconds,
  });

  @override
  State<HalamanPemutarVideo> createState() => _HalamanPemutarVideoState();
}

class _HalamanPemutarVideoState extends State<HalamanPemutarVideo> {
  late VideoPlayerController _controller;
  int _durasiLompatan = 10;
  Timer? _historyTimer;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndInitializePlayer();
  }

  Future<void> _loadSettingsAndInitializePlayer() async {
    // Inisialisasi secara sinkron dulu sebelum await
    if (widget.pathVideo.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.pathVideo));
    } else {
      _controller = VideoPlayerController.file(File(widget.pathVideo));
    }

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        
        // Melompat ke menit terakhir (resume) jika ada
        if (widget.progressSeconds != null && widget.progressSeconds! > 0) {
           _controller.seekTo(Duration(seconds: widget.progressSeconds!));
        }

        _controller.play();

        // Menyimpan durasi secara berkala (real-time) setiap 15 detik
        _historyTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
          _simpanRiwayatKeDatabase();
        });
      }
    });

    // Baru muat pengaturan secara asinkron
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _durasiLompatan = prefs.getInt('forwardPlayerDuration') ?? 10;
      });
    }
  }

  Future<void> _simpanRiwayatKeDatabase() async {
    if (widget.idFilm == null || !_controller.value.isInitialized) return;
    
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid == null) return;

    final progress = _controller.value.position.inSeconds;
    final total = _controller.value.duration.inSeconds;

    // Jangan simpan jika baru detik pertama (0-2) untuk mengurangi spam DB
    if (progress > 2) {
      await DatabaseHelper.instance.simpanHistory(userUid, widget.idFilm!, progress, total);
    }
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    _simpanRiwayatKeDatabase(); // Simpan saat keluar
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.judul),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                // Gunakan Stack untuk menumpuk video player dan tombol kontrol
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Lapisan 1: Video Player
                    VideoPlayer(_controller),
                    // Lapisan 2: Kontrol Play/Pause di tengah layar
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      // Latar belakang semi-transparan agar ikon terlihat
                      child: Container(
                        color: Colors.black.withOpacity(0.0), // Tidak terlihat
                        child: Center(
                          child: Icon(
                            _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 60.0,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),

                    // Lapisan 3: Kontrol Lompat Maju/Mundur
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Tombol Mundur
                        IconButton(
                          icon: const Icon(Icons.replay_10_outlined), // Ganti angka jika perlu
                          iconSize: 40,
                          color: Colors.white,
                          onPressed: () async {
                            final position = await _controller.position;
                            if (position != null) {
                              _controller.seekTo(position - Duration(seconds: _durasiLompatan));
                            }
                          },
                        ),
                        
                        // Spacer untuk area tengah
                        const SizedBox(width: 80),

                        // Tombol Maju
                        IconButton(
                          icon: const Icon(Icons.forward_10_outlined),
                          iconSize: 40,
                          color: Colors.white,
                          onPressed: () async {
                            final position = await _controller.position;
                            if (position != null) {
                              _controller.seekTo(position + Duration(seconds: _durasiLompatan));
                            }
                          },
                        ),
                      ],
                    ),

                    // Lapisan 4: Progress Bar di bawah
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.all(10.0),
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}