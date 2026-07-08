import 'package:flutter/material.dart';

class HalamanUnduhan extends StatefulWidget {
  const HalamanUnduhan({super.key});

  @override
  State<HalamanUnduhan> createState() => _HalamanUnduhanState();
}

class _HalamanUnduhanState extends State<HalamanUnduhan> {

  // Kita tidak perlu state management atau file reading lagi

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unduhan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Kita langsung tampilkan list-nya, tanpa loading atau cek file
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Ini adalah item statis yang kita buat persis seperti desain
          _buildUnduhanItem(
            posterPath: 'assets/images/poster_unduhan.png',
            episodeCount: '1 Eps',
            title: 'Fights Break Sphere',
          ),
         
        ],
      ),
    );
  }

  // Helper widget biar rapi
  // lalu ganti dengan kode ini:
  Widget _buildUnduhanItem({
    required String posterPath,
    required String episodeCount,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column( // <-- UBAH DARI ROW JADI COLUMN
        crossAxisAlignment: CrossAxisAlignment.start, // Agar rata kiri
        children: [
          // --- POSTER ---
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              posterPath,
              width: 100,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8), // <-- Tambah jarak vertikal di sini

          // --- INFO SERIAL (DI BAWAH POSTER) ---
          // Teks Jumlah Episode
          Text(
            episodeCount, // Teks statis dari desain
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          // Judul Serial
          Text(
            title, // Teks statis dari desain
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}