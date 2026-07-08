// lib/halaman_favorit.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/models/serial_tv.dart';
import 'package:aplikasi_mobile/halaman_detail_film.dart';
import 'package:aplikasi_mobile/services/database_helper.dart'; // Import SQLite

class HalamanFavorit extends StatefulWidget {
  const HalamanFavorit({super.key});

  @override
  State<HalamanFavorit> createState() => _HalamanFavoritState();
}

class _HalamanFavoritState extends State<HalamanFavorit> {
  // Dapatkan user yang sedang login
  final User? _pengguna = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildFavoriteGrid(),
    );
  }

  Widget _buildFavoriteGrid() {
    if (_pengguna == null) {
      return const Center(
        child: Text(
          'Silakan login untuk melihat favorite Anda.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Gunakan FutureBuilder untuk mengambil data dari API MySQL
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.ambilSemuaFavorite(_pengguna.uid), // Masukkan UID ke sini
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Terjadi kesalahan.'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Favorite kamu masih kosong.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final daftarFavorite = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2 / 3, 
          ),
          itemCount: daftarFavorite.length,
          itemBuilder: (context, index) {
            final data = daftarFavorite[index];
            
            // Buat objek SerialTv dummy untuk dikirim ke halaman detail
            final serial = SerialTv(
              // Paksa ubah menjadi String dulu (jaga-jaga), lalu parse jadi Integer
              id: int.parse(data['id'].toString()), 
              nama: data['nama'].toString(),
              pathPoster: data['pathPoster'].toString(),
              ringkasan: '', // Kosongkan karena tidak dibutuhkan di sini
              rataRataSuara: 0.0, // Kosongkan
            );

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HalamanDetailFilm(serial: serial),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    // Kita ganti ClipRRect sederhana dengan style dari home_screen
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28), // Radius border luar
                        border: Border.all(
                          color: const Color(0xFF00F5FF), // Warna border cyan
                          width: 2.0,
                        ),
                      ),
                      // ClipRRect ini untuk melengkungkan gambar di DALAM border
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26), // Radius dalam (lebih kecil dari border)
                        child: Image.network(
                          serial.pathPoster,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          // Kita tambahkan ini biar konsisten dengan home_screen
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
                  ),
                  const SizedBox(height: 8),
                  Text(
                    serial.nama,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
