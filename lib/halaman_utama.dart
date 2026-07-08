// lib/halaman_utama.dart
import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/home_screen.dart';
import 'package:aplikasi_mobile/halaman_favorit.dart';
import 'package:aplikasi_mobile/halaman_profil.dart';

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  // Variabel untuk melacak tab/halaman mana yang sedang aktif
  int _indeksHalamanTerpilih = 0;

  // Daftar semua halaman utama kita
  static const List<Widget> _daftarHalaman = <Widget>[
    HomeScreen(),
    HalamanFavorit(),
    HalamanProfil(),
  ];

  // Fungsi yang akan dipanggil saat item navigasi ditekan
  void _onItemTapped(int index) {
    setState(() {
      _indeksHalamanTerpilih = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan menampilkan halaman yang sesuai dengan indeks yang terpilih
      body: Center(child: _daftarHalaman.elementAt(_indeksHalamanTerpilih)),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(0, 11, 3, 223),
        iconSize: 28,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), // Ikon saat aktif
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _indeksHalamanTerpilih,
        onTap: _onItemTapped, // Panggil fungsi saat item ditekan

        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true, // TAMPILKAN label saat tidak aktif
        showSelectedLabels: true, // TAMPILKAN label saat aktif
      ),
    );
  }
}
