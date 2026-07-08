import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/models/serial_tv.dart';
import 'package:aplikasi_mobile/halaman_detail_film.dart';

class HalamanLihatSemua extends StatelessWidget {
  final String judul;
  final Future<List<SerialTv>> futureDaftarSerial;

  const HalamanLihatSemua({
    super.key,
    required this.judul,
    required this.futureDaftarSerial,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Tombol kembali sudah otomatis ada
        title: Text(judul),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<SerialTv>>(
        future: futureDaftarSerial,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final daftarSerial = snapshot.data!;
            // Kita gunakan GridView yang sama seperti di home
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2 / 3.5,
              ),
              itemCount: daftarSerial.length,
              itemBuilder: (context, index) {
                final serial = daftarSerial[index];
                // Menggunakan UI poster yang sudah kita sempurnakan
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFF00F5FF),
                              width: 2.0,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.network(
                              serial.pathPoster,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: Colors.grey[850]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        serial.nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Tidak ada film ditemukan'));
        },
      ),
    );
  }
}