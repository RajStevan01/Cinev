import 'package:flutter/material.dart';

// Enum untuk mengelola tab yang aktif
enum PremiumTab { beli, riwayat }

class HalamanPremium extends StatefulWidget {
  const HalamanPremium({super.key});

  @override
  State<HalamanPremium> createState() => _HalamanPremiumState();
}

class _HalamanPremiumState extends State<HalamanPremium> {
  // State untuk melacak tab yang dipilih
  PremiumTab _selectedTab = PremiumTab.beli;

  // Warna yang kita pakai
  static const Color cardColor = Color(0xFF2E394B);
  static const Color activeColor = Color(0xFF8A60FF);
  static const Color inactiveColor = Color(0xFF3D3D47);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background halaman kita samakan dengan profil
      backgroundColor: const Color(0xFF1F2228),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTabBar(),
            const SizedBox(height: 24),

            // Tampilkan konten berdasarkan tab yang aktif
            if (_selectedTab == PremiumTab.beli)
              _buildKontenBeli()
            else
              _buildKontenRiwayat(),
          ],
        ),
      ),
    );
  }

  // WIDGET UNTUK HEADER
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREMIUM CENTER',
            style: TextStyle(
              color: activeColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kelola Langganan premium dan lihat riwayat transaksi anda',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // WIDGET UNTUK TAB
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Tombol Beli Premium
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text(
                'Beli Premium',
                style: TextStyle(fontWeight: FontWeight.bold), // <-- TAMBAH INI
              ),
              onPressed: () {
                setState(() {
                  _selectedTab = PremiumTab.beli;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTab == PremiumTab.beli
                    ? activeColor
                    : inactiveColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Tombol Riwayat Transaksi
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.history_outlined),
              label: const Text('Riwayat Transaksi',
              style: TextStyle(fontWeight: FontWeight.bold),),
              onPressed: () {
                setState(() {
                  _selectedTab = PremiumTab.riwayat;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTab == PremiumTab.riwayat
                    ? activeColor
                    : inactiveColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- KONTEN UNTUK TAB "BELI PREMIUM" ---
  Widget _buildKontenBeli() {
    return Column(
      children: [
        _buildPaketItem(
          icon: Icons.brightness_auto_outlined,
          title: 'Premium 1 Bulan',
          price: 'Rp 1.000.000.000',
          subtitle: 'Kelola Langganan premium dan lihat riwayat transaksi anda',
        ),
        const SizedBox(height: 16),
        _buildPaketItem(
          icon: Icons.star_border_purple500_outlined,
          title: 'Premium 3 Bulan',
          price: 'Rp 3.000.000.000',
          subtitle:
          'Pilihan populer untuk pengguna jangka menengah, dengan bonus tambahan exp sebanyak 50k',
        ),
      ],
    );
  }

  Widget _buildPaketItem({
    required IconData icon,
    required String title,
    required String price,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            price,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {}, // Sesuai instruksi, hiasan aja
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Beli Sekarang', style: TextStyle(fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }

  // --- KONTEN UNTUK TAB "RIWAYAT TRANSAKSI" ---
  Widget _buildKontenRiwayat() {
    return Column(
      children: [
        _buildFilterRiwayat(),
        const SizedBox(height: 16),
        _buildRiwayatKosong(),
      ],
    );
  }

  Widget _buildFilterRiwayat() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inactiveColor,
                    foregroundColor: Colors.white70,
                  ),
                  child: const Text('Semua Status'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inactiveColor,
                    foregroundColor: Colors.white70,
                  ),
                  child: const Text('Semua Periode'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Total: 0 transaksi',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatKosong() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'Belum Ada Transaksi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Anda belum memiliki riwayat transaksi premium',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}