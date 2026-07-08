// lib/halaman_pencarian.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/models/serial_tv.dart';
import 'package:aplikasi_mobile/services/api_service.dart';
import 'package:aplikasi_mobile/halaman_detail_film.dart';

class HalamanPencarian extends StatefulWidget {
  const HalamanPencarian({super.key});

  @override
  State<HalamanPencarian> createState() => _HalamanPencarianState();
}

class _HalamanPencarianState extends State<HalamanPencarian> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<SerialTv> _hasilPencarian = [];
  List<String> _trendingKeywords = [];
  bool _isLoading = false;
  bool _hasSearched = false; // Untuk melacak apakah pencarian pernah dilakukan

  @override
  void initState() {
    super.initState();
    _ambilTrending();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _ambilTrending() async {
    final keywords = await _apiService.ambilTrendingKeywords();
    if (mounted) {
      setState(() {
        _trendingKeywords = keywords;
      });
    }
  }

  // Fungsi ini dipanggil setiap kali teks di search bar berubah
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _lakukanPencarian(_searchController.text);
    });
  }

  Future<void> _lakukanPencarian(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _hasilPencarian = [];
          _hasSearched = false; // Kembali ke state awal jika query kosong
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _apiService.cariSerialTv(query);
      if (mounted) {
        setState(() {
          _hasilPencarian = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasilPencarian = [];
        });
      }
      // Opsional: tampilkan snackbar jika ada error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SEARCH BAR & TOMBOL CARI ---
              // lalu ganti dengan kode ini:
              // --- SEARCH BAR & TOMBOL CARI ---
              Row(
                children: [
                  // TOMBOL KEMBALI BARU
                  IconButton(
                    // Menggunakan ikon yang mirip '<'
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () {
                      // Fungsi untuk kembali ke halaman sebelumnya
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(
                    width: 8,
                  ), // Jarak antara tombol dan search bar
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true, // Langsung fokus ke search bar
                      decoration: InputDecoration(
                        hintText: 'Cari Film...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[850],
                      ),
                      onSubmitted: _lakukanPencarian, // Bisa cari via keyboard
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => _lakukanPencarian(_searchController.text),
                    child: const Text('Cari', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- CHIPS REKOMENDASI (TRENDING) ---
              if (!_hasSearched) // Tampilkan hanya jika belum mencari
                Wrap(
                  spacing: 8.0,
                  children: _trendingKeywords.map((keyword) {
                    return ActionChip(
                      label: Text(keyword),
                      onPressed: () {
                        _searchController.text = keyword;
                        _lakukanPencarian(keyword);
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),

              // --- AREA HASIL PENCARIAN ---
              Expanded(child: _buildHasilWidget()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHasilWidget() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      // Tampilan awal sebelum user mencari apa-apa
      return const SizedBox.shrink(); // Widget kosong
    }

    if (_hasilPencarian.isEmpty) {
      return const Center(
        child: Text(
          'Film tidak ditemukan.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // Tampilan hasil pencarian dalam Grid 3 kolom
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2 / 3, // Rasio standar poster
      ),
      itemCount: _hasilPencarian.length,
      itemBuilder: (context, index) {
        final serial = _hasilPencarian[index];

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
              // Expanded agar gambar mengisi ruang yang tersedia
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    serial.pathPoster,
                    fit: BoxFit.cover,
                    width: double.infinity, // Memastikan gambar memenuhi lebar
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[850],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[850],
                        child: const Icon(Icons.movie, color: Colors.white54),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8), // Jarak antara gambar dan judul
              // Judul film
              Text(
                serial.nama,
                maxLines: 2, // Batasi judul jadi 2 baris
                overflow:
                    TextOverflow.ellipsis, // Tambahkan ... jika lebih panjang
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // Ukuran font yang pas untuk grid
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
