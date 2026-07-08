import 'package:aplikasi_mobile/halaman_pemutar_video.dart';
import 'package:flutter/material.dart';

class HalamanEpisodeUnduhan extends StatelessWidget {
  final String namaSerial;
  final List<String> daftarPathEpisode;

  const HalamanEpisodeUnduhan({
    super.key,
    required this.namaSerial,
    required this.daftarPathEpisode,
  });

  @override
  Widget build(BuildContext context) {
    // Urutkan path episode agar tampil berurutan
    daftarPathEpisode.sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(namaSerial),
        backgroundColor: Colors.transparent,
        elevation: 08,
      ),
      body: ListView.builder(
        itemCount: daftarPathEpisode.length,
        itemBuilder: (context, index) {
          final pathFile = daftarPathEpisode[index];
          // Ekstrak nomor episode dari nama file, contoh: '.../Nama Serial_ep1.mp4' -> '1'
          final String namaFile = pathFile.split('/').last;
          final String nomorEpisode =
              namaFile.split('_ep').last.split('.').first;

          return ListTile(
            leading: const Icon(Icons.play_circle_fill_outlined),
            title: Text('Episode $nomorEpisode'),
            onTap: () {
              // Navigasi ke Halaman Player Offline
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HalamanPemutarVideo(
                    pathVideo: pathFile,
                    judul: '$namaSerial - Episode $nomorEpisode',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}