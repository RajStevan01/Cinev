import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebijakan Privasi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kebijakan Privasi Aplikasi Kami',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Terakhir diperbarui: 16 Oktober 2025',
              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            const Text(
              'Selamat datang di aplikasi kami. Kami menghargai privasi Anda dan berkomitmen untuk melindunginya. Kebijakan Privasi ini menjelaskan informasi apa yang kami kumpulkan, bagaimana kami menggunakannya, dan pilihan apa yang Anda miliki terkait informasi tersebut.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(
              '1. Informasi yang Kami Kumpulkan',
               style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Kami dapat mengumpulkan informasi yang Anda berikan langsung kepada kami, seperti saat Anda membuat akun, memperbarui profil Anda, atau menghubungi kami. Informasi ini dapat mencakup nama pengguna, alamat email, dan foto profil.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
             Text(
              '2. Bagaimana Kami Menggunakan Informasi Anda',
               style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
             const Text(
              'Informasi yang kami kumpulkan digunakan untuk mengoperasikan, memelihara, dan menyediakan fitur dan fungsionalitas aplikasi kami, serta untuk berkomunikasi dengan Anda secara langsung.',
               style: TextStyle(fontSize: 16, height: 1.5),
            ),
            // ... (Tambahkan sisa teks kebijakan privasi di sini) ...
          ],
        ),
      ),
    );
  }
}