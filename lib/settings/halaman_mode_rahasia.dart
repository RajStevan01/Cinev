import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfidentialModePage extends StatefulWidget {
  const ConfidentialModePage({super.key});

  @override
  State<ConfidentialModePage> createState() => _ConfidentialModePageState();
}

class _ConfidentialModePageState extends State<ConfidentialModePage> {
  bool _isConfidentialModeOn = false;
  // Kita bisa tambahkan variabel untuk setting lain jika perlu dikembangkan
  // String _expiration = 'Berakhir dalam 1 minggu';
  // String _passcodeType = 'Standar';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Muat pengaturan yang sudah tersimpan
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isConfidentialModeOn = prefs.getBool('confidentialModeOn') ?? false;
    });
  }

  // Simpan pengaturan baru
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('confidentialModeOn', _isConfidentialModeOn);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan disimpan.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Tombol Batal
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('BATAL', style: TextStyle(color: Colors.white)),
        ),
        leadingWidth: 80,
        // Tombol Simpan
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('SIMPAN', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Opsi Confidential mode
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Confidential mode', style: TextStyle(fontSize: 18)),
            trailing: Switch(
              value: _isConfidentialModeOn,
              onChanged: (value) {
                setState(() {
                  _isConfidentialModeOn = value;
                });
              },
              activeThumbColor: const Color(0xFF8A60FF),
            ),
          ),
          const Divider(color: Colors.white24),
          
          // Opsi Set Expiration (UI Statis)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Set Expiration'),
            subtitle: Text(
              'Berakhir dalam 1 minggu',
              style: TextStyle(color: _isConfidentialModeOn ? Colors.white70 : Colors.grey[700]),
            ),
            onTap: _isConfidentialModeOn ? () {} : null, // Hanya bisa di-tap jika mode aktif
          ),
          const Divider(color: Colors.white24),

          // Opsi Require passcode (UI Statis)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Require passcode'),
            subtitle: Text(
              'Semua kode sandi akan dibuat oleh Googel. Penerima non-Gmail akan mendapat kode sandi untuk melakukan autentikasi.',
              style: TextStyle(color: _isConfidentialModeOn ? Colors.white70 : Colors.grey[700]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Standar', style: TextStyle(color: _isConfidentialModeOn ? Colors.white : Colors.grey[700])),
                Icon(Icons.arrow_drop_down, color: _isConfidentialModeOn ? Colors.white : Colors.grey[700]),
              ],
            ),
             onTap: _isConfidentialModeOn ? () {} : null,
          ),
           const Divider(color: Colors.white24),
        ],
      ),
    );
  }
}