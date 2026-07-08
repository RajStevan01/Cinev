import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aplikasi_mobile/settings/halaman_foto.dart';
import 'package:aplikasi_mobile/settings/halaman_mode_rahasia.dart';


class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _subjekController = TextEditingController();
  final _pesanController = TextEditingController();
  final String _emailPenerima = 'admin@movie.net';
  final String? _emailPengirim = FirebaseAuth.instance.currentUser?.email;

  Future<void> _kirimEmail() async {
    final subjek = _subjekController.text;
    final pesan = _pesanController.text;

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: _emailPenerima,
      query:
          'subject=${Uri.encodeComponent(subjek)}&body=${Uri.encodeComponent(pesan)}',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat menemukan aplikasi email.')),
      );
    }
  }

  void _showScheduleSendDialog(BuildContext context) {
    // Helper function untuk menangani aksi saat item ditekan
    void handleOptionSelected(String option) {
      Navigator.of(context).pop(); // Tutup dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email akan dijadwalkan untuk: $option'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Helper widget untuk membuat setiap tombol di grid
    Widget buildScheduleOption({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.orangeAccent),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          backgroundColor: Colors.grey[850],
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jadwalkan pengiriman', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                // Gunakan GridView agar layout rapi
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    buildScheduleOption(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Besok pagi',
                      subtitle: '30 Sep, 08.00',
                      onTap: () => handleOptionSelected('Besok pagi'),
                    ),
                    buildScheduleOption(
                      icon: Icons.brightness_5_outlined,
                      title: 'Besok siang',
                      subtitle: '30 Sep, 13.00',
                      onTap: () => handleOptionSelected('Besok siang'),
                    ),
                    buildScheduleOption(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Senin pagi',
                      subtitle: '06 Okt, 08.00',
                      onTap: () => handleOptionSelected('Senin pagi'),
                    ),
                    buildScheduleOption(
                      icon: Icons.calendar_today_outlined,
                      title: 'Pilih tanggal & waktu',
                      subtitle: '', // Kosongkan subtitle atau isi sesuai kebutuhan
                      onTap: () => handleOptionSelected('Pilih tanggal & waktu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _subjekController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  void _showAttachmentMenu(BuildContext context) {
    // Menemukan posisi tombol paperclip di layar
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    // Menampilkan menu popup
    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'foto',
          child: ListTile(
            leading: Icon(Icons.photo_outlined),
            title: Text('Foto'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'kamera',
          child: ListTile(
            leading: Icon(Icons.camera_alt_outlined),
            title: Text('Kamera'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'file',
          child: ListTile(
            leading: Icon(Icons.insert_drive_file_outlined),
            title: Text('File'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'drive',
          child: ListTile(
            leading: Icon(Icons.cloud_upload_outlined),
            title: Text('Drive'),
          ),
        ),
      ],
    ).then((String? value) {
      if (value == 'foto') {
        // Jika "Foto" dipilih, tampilkan Draggable Bottom Sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // WAJIB: agar sheet bisa full screen
          backgroundColor: Colors.transparent, // Latar belakang transparan
          builder: (context) => const FakeGallerySheet(),
        );
      } else if (value != null) {
        // Untuk pilihan lain, tetap tampilkan pesan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fungsionalitas untuk "$value" belum tersedia.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontak Kami'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // --- IKON BARU DITAMBAHKAN DI SINI ---
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.attachment),
                onPressed: () {
                  // Panggil fungsi untuk menampilkan menu
                  _showAttachmentMenu(context);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: _kirimEmail,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'Jadwalkan pengiriman') {
                _showScheduleSendDialog(context);
              } else if (value == 'Mode rahasia') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConfidentialModePage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fitur "$value" belum diimplementasikan.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Jadwalkan pengiriman',
                child: Text('Jadwalkan pengiriman'),
              ),
              const PopupMenuItem<String>(
                value: 'Tambahkan dari Kontak',
                child: Text('Tambahkan dari Kontak'),
              ),
              const PopupMenuItem<String>(
                value: 'Mode rahasia',
                child: Text('Mode rahasia'),
              ),
              const PopupMenuItem<String>(
                value: 'Simpan draf',
                child: Text('Simpan draf'),
              ),
              const PopupMenuItem<String>(
                value: 'Hapus',
                child: Text('Hapus'),
              ),
              const PopupMenuItem<String>(
                value: 'Setelan',
                child: Text('Setelan'),
              ),
              const PopupMenuItem<String>(
                value: 'Bantuan & Masukan',
                child: Text('Bantuan & Masukan'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoField(
              label: 'Dari',
              value: _emailPengirim ?? 'Tidak diketahui',
            ),
            const Divider(color: Colors.white24),
            _buildInfoField(label: 'Kepada', value: _emailPenerima),
            const Divider(color: Colors.white24),
            TextField(
              controller: _subjekController,
              decoration: const InputDecoration(
                hintText: 'Subjek',
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white24),
            TextField(
              controller: _pesanController,
              maxLines: 15, // Area tulis yang lebih besar
              decoration: const InputDecoration(
                hintText: 'Tulis pesan Anda...',
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk field "Dari" dan "Kepada"
  Widget _buildInfoField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
