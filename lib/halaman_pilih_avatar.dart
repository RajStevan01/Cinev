import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Enum untuk mengelola mode yang sedang aktif
enum AvatarMode { preset, custom }

class HalamanPilihAvatar extends StatefulWidget {
  const HalamanPilihAvatar({super.key});

  @override
  State<HalamanPilihAvatar> createState() => _HalamanPilihAvatarState();
}

class _HalamanPilihAvatarState extends State<HalamanPilihAvatar> {
  // State awal adalah mode Avatar Preset
  AvatarMode _modeSaatIni = AvatarMode.preset;
  File? _fileGambarTerpilih; // Variabel untuk menyimpan gambar pilihan
  // Variabel untuk menyimpan URL avatar dari Firebase Storage
  List<String> _daftarUrlAvatarPreset = [];
  bool _isLoadingPreset = true; // State loading untuk avatar preset

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER ---
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Pilih Avatar',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- TOMBOL TOGGLE MODE ---
              _buildTombolToggle(),
              const SizedBox(height: 32),

              // Tampilkan UI yang sesuai dengan mode yang aktif
              Expanded(
                child: _modeSaatIni == AvatarMode.preset
                    ? _buildUIAvatarPreset()
                    : _buildUIUploadCustom(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _muatAvatarPreset();
  }

  // Fungsi untuk mengambil daftar URL avatar dari Firebase Storage
  Future<void> _muatAvatarPreset() async {
    try {
      // Akses folder 'avatars' di Firebase Storage
      final listResult = await FirebaseStorage.instance
          .ref('avatars')
          .listAll();

      // Ambil URL download untuk setiap item di folder
      final urls = await Future.wait(
        listResult.items.map((item) => item.getDownloadURL()),
      );

      // Perbarui state dengan daftar URL yang didapat
      if (mounted) {
        setState(() {
          // Konversi List<dynamic> menjadi List<String> secara aman
          _daftarUrlAvatarPreset = List<String>.from(urls);
          _isLoadingPreset = false;
        });
      }
    } catch (e) {
      // Tangani error jika terjadi (misal: izin ditolak)
      if (!mounted) return; // <-- TAMBAHKAN PENGECEKAN INI
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  // Widget untuk tombol toggle "Avatar Preset" dan "Upload Custom"
  Widget _buildTombolToggle() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _modeSaatIni = AvatarMode.preset;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _modeSaatIni == AvatarMode.preset
                  ? Theme.of(context).primaryColor
                  : Colors.grey[850],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Avatar Preset'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _modeSaatIni = AvatarMode.custom;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _modeSaatIni == AvatarMode.custom
                  ? Theme.of(context).primaryColor
                  : Colors.grey[850],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Upload Custom'),
          ),
        ),
      ],
    );
  }

  // Widget untuk UI "Avatar Preset" (masih placeholder)
  Widget _buildUIAvatarPreset() {
    // Data filter placeholder
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Pilih avatar gratis', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        // --- FILTER CHIPS ---
        Wrap(
          spacing: 8.0,
          children: [
            'Semua',
            'Alya',
            'Anna Yanami',
            'Nakamoto',
          ].map((filter) => Chip(label: Text(filter))).toList(),
        ),
        const SizedBox(height: 24),

        // --- GRID AVATAR ---
        Expanded(
          child: _isLoadingPreset
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _daftarUrlAvatarPreset.length,
                  itemBuilder: (context, index) {
                    final urlGambar = _daftarUrlAvatarPreset[index];
                    return GestureDetector(
                      onTap: () {
                        // Kembali dan kirim data URL avatar yang dipilih
                        Navigator.of(context).pop(urlGambar);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          urlGambar,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 24),
        // Tombol Batal
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.grey[700]!),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  Future<void> _pilihGambarDariGaleri() async {
    final picker = ImagePicker();
    try {
      // Buka galeri dan tunggu pengguna memilih gambar
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        // Jika pengguna berhasil memilih file, simpan file tersebut ke state
        setState(() {
          _fileGambarTerpilih = File(pickedFile.path);
        });
        // TODO: Tambahkan validasi ukuran file di sini nanti
      }
    } catch (e) {
      // Tangani error jika terjadi (misal: izin ditolak)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  // Widget untuk UI "Upload Custom"
  Widget _buildUIUploadCustom() {
    return Column(
      children: [
        // --- AREA UPLOAD (YANG SEKARANG DINAMIS) ---
        Expanded(
          child: GestureDetector(
            onTap:
                _pilihGambarDariGaleri, // Bisa diklik di mana saja di area ini
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[700]!,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              // Tampilkan pratinjau JIKA gambar sudah dipilih
              child: _fileGambarTerpilih != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(
                        11,
                      ), // Agar pas di dalam border
                      child: Image.file(
                        _fileGambarTerpilih!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  // Tampilan default JIKA gambar belum dipilih
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 60,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Ketuk untuk memilih gambar',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Maksimal 2 MB: JPG, PNG, GIF',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // --- TOMBOL AKSI BAWAH ---
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pop(), // Kembali tanpa data
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                // Tombol Simpan hanya aktif jika gambar sudah dipilih
                onPressed: _fileGambarTerpilih != null
                    ? () {
                        // Kembali dan kirim data file gambar yang dipilih
                        Navigator.of(context).pop(_fileGambarTerpilih);
                      }
                    : null, // null akan membuat tombol disable
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
