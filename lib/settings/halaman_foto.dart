// lalu ganti dengan seluruh kode baru ini:
import 'package:flutter/material.dart';

// Enum baru untuk mengelola tab yang aktif
enum GalleryTab { foto, koleksi }

class FakeGallerySheet extends StatefulWidget {
  const FakeGallerySheet({super.key});

  @override
  State<FakeGallerySheet> createState() => _FakeGallerySheetState();
}

class _FakeGallerySheetState extends State<FakeGallerySheet> {
  final DraggableScrollableController _scrollController = DraggableScrollableController();
  bool _isHandleVisible = true;
  // State untuk melacak tab yang dipilih, defaultnya "Foto"
  GalleryTab _selectedTab = GalleryTab.foto;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final bool shouldBeVisible = _scrollController.size < 0.9;
      if (shouldBeVisible != _isHandleVisible) {
        setState(() {
          _isHandleVisible = shouldBeVisible;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- WIDGET BARU UNTUK TAMPILAN TAB FOTO ---
  Widget _buildFotoGrid(ScrollController scrollController) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 51,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pemilihan foto belum diimplementasikan.')),
            );
          },
          child: Container(
            color: Colors.grey[800],
            child: Image.network(
              'https://picsum.photos/seed/${index + 1}/200/300',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET BARU UNTUK TAMPILAN TAB KOLEKSI ---
  Widget _buildKoleksiGrid(ScrollController scrollController) {
    // Daftar nama album placeholder
    final List<String> albumNames = [
      'Favorit', 'Kamera', 'Orang', 'Dari Perangkat ini',
      'Dari aplikasi', 'Screenshot'
    ];

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Telusuri',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Grid album
        Expanded(
          child: GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 kolom untuk album
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0, // Membuat item menjadi kotak
            ),
            itemCount: albumNames.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.of(context).pop(); // Tutup panel
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fungsionalitas ini belum tersedia.')),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Placeholder untuk thumbnail album
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(albumNames[index]),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _scrollController,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 1.0,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              AnimatedOpacity(
                // ... (kode drag handle tidak berubah)
                opacity: _isHandleVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    // --- TOMBOL "FOTO" (SEKARANG DINAMIS) ---
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _selectedTab = GalleryTab.foto),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTab == GalleryTab.foto ? const Color(0xFF8A60FF) : Colors.grey[800],
                          foregroundColor: _selectedTab == GalleryTab.foto ? Colors.white : Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // --- TOMBOL "KOLEKSI" (SEKARANG DINAMIS) ---
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _selectedTab = GalleryTab.koleksi),
                        icon: const Icon(Icons.collections),
                        label: const Text('Koleksi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTab == GalleryTab.koleksi ? const Color(0xFF8A60FF) : Colors.grey[800],
                          foregroundColor: _selectedTab == GalleryTab.koleksi ? Colors.white : Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // --- TAMPILKAN GRID SESUAI TAB YANG AKTIF ---
              Expanded(
                child: _selectedTab == GalleryTab.foto
                    ? _buildFotoGrid(scrollController)
                    : _buildKoleksiGrid(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }
}