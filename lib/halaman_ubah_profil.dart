//halaman_ubah_profil.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_mobile/halaman_pilih_avatar.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:aplikasi_mobile/services/database_helper.dart';

class HalamanUbahProfil extends StatefulWidget {
  const HalamanUbahProfil({super.key});

  @override
  State<HalamanUbahProfil> createState() => _HalamanUbahProfilState();
}

class _HalamanUbahProfilState extends State<HalamanUbahProfil> {
  final _auth = FirebaseAuth.instance;
  // Hapus instansiasi Firestore

  // Controller untuk field nama pengguna
  final _namaPenggunaController = TextEditingController();

  User? _pengguna;
  String? _emailPengguna;
  String? _urlFotoProfil;
  bool _isLoading = true;
  File? _fileGambarProfilBaru;
  String? _urlAvatarPresetBaru;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _muatDataPengguna();
  }

  @override
  void dispose() {
    _namaPenggunaController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil data awal pengguna
  Future<void> _muatDataPengguna() async {
    _pengguna = _auth.currentUser;
    if (_pengguna != null) {
      // Ambil data langsung dari Auth, tidak pakai Firestore lagi
      setState(() {
        _namaPenggunaController.text = _pengguna!.displayName ?? '';
        _emailPengguna = _pengguna!.email;
        _urlFotoProfil = _pengguna!.photoURL;
        _isLoading = false;
      });
    }
  }

  Future<void> _simpanPerubahan() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (_pengguna == null) return;

      String? urlFotoProfilUpdate;

      if (_fileGambarProfilBaru != null) {
        final ref = FirebaseStorage.instance
            .ref('profile_pictures')
            .child('${_pengguna!.uid}.jpg');
        await ref.putFile(_fileGambarProfilBaru!);
        urlFotoProfilUpdate = await ref.getDownloadURL();
      } else if (_urlAvatarPresetBaru != null) {
        urlFotoProfilUpdate = _urlAvatarPresetBaru;
      }

      // Update data langsung ke Firebase Auth
      await _pengguna!.updateDisplayName(_namaPenggunaController.text.trim());
      
      if (urlFotoProfilUpdate != null) {
        await _pengguna!.updatePhotoURL(urlFotoProfilUpdate);
      }

      // Reload user untuk memastikan data terbaru terambil
      await _pengguna!.reload();

      // SIMPAN KE MYSQL MELALUI API
      await DatabaseHelper.instance.updateProfilUser(
        _pengguna!.uid,
        urlFotoProfilUpdate,
        _namaPenggunaController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Edit Profile'),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : _simpanPerubahan,
                child: const Text('Simpan', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack( // <-- Stack BARU (luar)
                          alignment: Alignment.center, // Biar avatar pas di tengah background
                          children: [
                            // 1. Background gradasi ungu dari gambar
                            ClipRRect( // <-- BUNGKUS DENGAN WIDGET INI
                              borderRadius: BorderRadius.circular(16), // <-- ATUR RADIUSNYA DI SINI
                              child: Image.asset(
                                'assets/images/background_profil.png',
                                width: 400,
                                height: 240,
                                fit: BoxFit.cover,
                              ),
                            ),

                            // 2. Stack lama (avatar + tombol kamera)
                            //    (Kita taruh di atas background)
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 84,
                                  backgroundColor: Color(0xFF000DFF),
                                  child: CircleAvatar(
                                    radius: 80,
                                    backgroundColor: Colors.grey,
                                    backgroundImage: _fileGambarProfilBaru != null
                                        ? FileImage(_fileGambarProfilBaru!)
                                        : (_urlAvatarPresetBaru != null
                                        ? NetworkImage(
                                      _urlAvatarPresetBaru!,
                                    )
                                        : (_urlFotoProfil != null
                                        ? NetworkImage(
                                      _urlFotoProfil!,
                                    )
                                        : null))
                                    as ImageProvider?,
                                    child:
                                    _urlFotoProfil == null &&
                                        _fileGambarProfilBaru == null &&
                                        _urlAvatarPresetBaru == null
                                        ? const Icon(
                                      Icons.person,
                                      size: 120,
                                      color: Colors.white70,
                                    )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final hasil = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                          const HalamanPilihAvatar(),
                                        ),
                                      );
                                      if (hasil == null) return;
                                      if (hasil is File) {
                                        setState(() {
                                          _fileGambarProfilBaru = hasil;
                                          _urlAvatarPresetBaru = null;
                                        });
                                      } else if (hasil is String) {
                                        setState(() {
                                          _urlAvatarPresetBaru = hasil;
                                          _fileGambarProfilBaru = null;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF000DFF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        'Nama Pengguna',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _namaPenggunaController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF2E394B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Alamat Email',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _emailPengguna ?? 'Tidak ada email',
                        readOnly: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF2E394B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        // --- WIDGET UNTUK OVERLAY LOADING ---
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(
              0.5,
            ), // Latar belakang gelap transparan
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
