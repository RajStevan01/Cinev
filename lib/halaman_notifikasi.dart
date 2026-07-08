import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/services/database_helper.dart';

class HalamanNotifikasi extends StatefulWidget {
  const HalamanNotifikasi({super.key});

  @override
  State<HalamanNotifikasi> createState() => _HalamanNotifikasiState();
}

class _HalamanNotifikasiState extends State<HalamanNotifikasi> {
  // Fungsi untuk menentukan ikon berdasarkan kategori notif
  IconData _dapatkanIkonKategori(String kategori) {
    switch (kategori) {
      case 'login':
        return Icons.security_outlined;
      case 'download':
        return Icons.download_done_rounded;
      case 'favorite':
        return Icons.favorite_border;
      case 'sistem':
        return Icons.campaign_outlined;
      case 'fcm':
        return Icons.notifications_active_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.ambilSemuaNotifikasi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Menampilkan pesan error asli untuk debugging
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.white54),
                  SizedBox(height: 16),
                  Text('Belum ada notifikasi', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            );
          }

          final daftarNotif = snapshot.data!;

          return ListView.builder(
            itemCount: daftarNotif.length,
            itemBuilder: (context, index) {
              final notif = daftarNotif[index];
              final bool belumDibaca = notif['dibaca'] == 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[850],
                  child: Icon(
                    _dapatkanIkonKategori(notif['kategori']),
                    color: const Color(0xFF00F5FF),
                  ),
                ),
                title: Text(
                  notif['judul'],
                  style: TextStyle(
                    fontWeight: belumDibaca ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notif['pesan'], style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      notif['waktu'],
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
                onTap: () async {
                  if (belumDibaca) {
                    await DatabaseHelper.instance.tandaiSudahDibaca(notif['id']);
                    setState(() {}); // Refresh UI agar teks tidak bold lagi
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
