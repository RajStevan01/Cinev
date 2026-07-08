import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syarat dan Ketentuan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Syarat dan Ketentuan Penggunaan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Efektif sejak: 16 Oktober 2025',
              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            const Text(
              'Harap baca Syarat dan Ketentuan ini dengan saksama sebelum menggunakan layanan kami. Dengan mengakses atau menggunakan aplikasi, Anda setuju untuk terikat oleh syarat dan ketentuan ini.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(
              '1. Akun Anda',
               style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Anda bertanggung jawab untuk menjaga kerahasiaan akun dan kata sandi Anda dan untuk membatasi akses ke perangkat Anda. Anda setuju untuk menerima tanggung jawab atas semua aktivitas yang terjadi di bawah akun atau kata sandi Anda.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
             Text(
              '2. Penggunaan Layanan',
               style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
             const Text(
              'Anda setuju untuk tidak menggunakan layanan untuk tujuan ilegal atau tidak sah. Anda tidak boleh, dalam penggunaan layanan, melanggar hukum apa pun di yurisdiksi Anda (termasuk namun tidak terbatas pada hukum hak cipta).',
               style: TextStyle(fontSize: 16, height: 1.5),
            ),
            // ... (Tambahkan sisa teks syarat dan ketentuan di sini) ...
          ],
        ),
      ),
    );
  }
}