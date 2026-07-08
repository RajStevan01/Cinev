import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseHelper {
  // Tetap menggunakan Singleton agar tidak perlu ubah cara panggil di file lain
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  DatabaseHelper._init();

  // PENTING: Atur Base URL sesuai dengan perangkamu!
  // - Jika pakai Emulator Android: 'http://10.0.2.2/cinev_api'
  // - Jika pakai HP Fisik/Real Device: IP Address WiFi laptopmu (contoh: 'http://192.168.1.15/cinev_api')
  static const String baseUrl = 'http://192.168.1.79/cinev_api';

  // ==========================================================
  // --- FUNGSI CRUD UNTUK WATCHLIST (MYSQL VIA API) ---
  // ==========================================================

  // 1. Mengecek apakah film sudah ada di favorit
  // ⚠️ PERHATIAN: Sekarang butuh parameter userUid
  Future<bool> cekFavorite(int id, String userUid) async {
    final url = Uri.parse('$baseUrl/cek_favorite.php?id=$id&user_uid=$userUid');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error cekFavorite: $e');
      return false;
    }
  }

  // 2. Menambahkan film ke favorit
  // ⚠️ PERHATIAN: Map data dari UI sekarang harus menyertakan 'user_uid'
  Future<int> tambahKeFavorite(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/tambah_favorite.php');
    
    try {
      final response = await http.post(
        url,
        body: {
          'id': data['id'].toString(),
          'user_uid': data['user_uid'].toString(),
          'nama': data['nama'].toString(),
          'pathPoster': data['pathPoster'].toString(),
          'tanggalDitambahkan': data['tanggalDitambahkan'].toString(), // KITA KIRIM TANGGAL DARI FLUTTER
        },
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        // Mengembalikan 1 (berhasil) atau 0 (gagal) agar selaras dengan pola lama sqflite
        return result['status'] == 'success' ? 1 : 0; 
      }
      return 0;
    } catch (e) {
      print('Error tambahKeFavorite: $e');
      return 0;
    }
  }

  // 3. Menghapus film dari favorit
  // ⚠️ PERHATIAN: Sekarang butuh parameter userUid
  Future<int> hapusDariFavorite(int id, String userUid) async {
    final url = Uri.parse('$baseUrl/hapus_favorite.php');
    
    try {
      final response = await http.post(
        url,
        body: {
          'id': id.toString(),
          'user_uid': userUid,
        },
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['status'] == 'success' ? 1 : 0;
      }
      return 0;
    } catch (e) {
      print('Error hapusDariFavorite: $e');
      return 0;
    }
  }

  // 4. Mengambil semua data dari favorit
  // ⚠️ PERHATIAN: Sekarang butuh parameter userUid
  Future<List<Map<String, dynamic>>> ambilSemuaFavorite(String userUid) async {
    final url = Uri.parse('$baseUrl/get_favorite.php?user_uid=$userUid');
    
    try {
      // Tambahkan timeout 5 detik di sini!
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      // Jika server mati atau timeout, akan langsung masuk ke sini
      print('Error ambilSemuaFavorite: $e');
      return []; // Mengembalikan list kosong, sehingga layar menunjukkan "Favorite Kosong" bukan loading
    }
  }

  // ==========================================================
  // --- FUNGSI CRUD UNTUK NOTIFIKASI (LONCENG) ---
  // ==========================================================

  Future<int> tambahNotifikasi(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/tambah_notifikasi.php');
    final userUid = FirebaseAuth.instance.currentUser?.uid ?? 'all';
    
    try {
      final response = await http.post(
        url,
        body: {
          'kategori': data['kategori'].toString(),
          'judul': data['judul'].toString(),
          'pesan': data['pesan'].toString(),
          'waktu': data['waktu'].toString(),
          'user_uid': userUid,
        },
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['status'] == 'success' ? 1 : 0;
      }
      return 0;
    } catch (e) {
      print('Error tambahNotifikasi: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> ambilSemuaNotifikasi() async {
    final userUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final url = Uri.parse('$baseUrl/get_notifikasi.php?user_uid=$userUid');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error ambilSemuaNotifikasi: $e');
      return [];
    }
  }

  Future<int> tandaiSudahDibaca(int id) async {
    print('⚠️ TODO: Buat API PHP untuk tandaiSudahDibaca jika dibutuhkan');
    return 1; // Dummy return
  }

  // ==========================================================
  // --- FUNGSI CRUD UNTUK HISTORY TONTONAN ---
  // ==========================================================
  Future<bool> simpanHistory(String userUid, int idFilm, int progressSeconds, int totalSeconds) async {
    final url = Uri.parse('$baseUrl/simpan_history.php');
    try {
      final response = await http.post(
        url,
        body: {
          'user_uid': userUid,
          'id_film': idFilm.toString(),
          'progress_seconds': progressSeconds.toString(),
          'total_seconds': totalSeconds.toString(),
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error simpanHistory: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> ambilRiwayatTontonan(String userUid) async {
    final url = Uri.parse('$baseUrl/get_history.php?user_uid=$userUid');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error ambilRiwayatTontonan: $e');
      return [];
    }
  }

  // ==========================================================
  // --- FUNGSI UNTUK MENYIMPAN USER KE MYSQL ---
  // ==========================================================
  Future<bool> simpanUserKeMySQL(String uid, String nama, String email) async {
    final url = Uri.parse('$baseUrl/simpan_user.php');
    
    try {
      final response = await http.post(
        url,
        body: {
          'uid': uid,
          'nama': nama,
          'email': email,
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('Berhasil kirim user ke MySQL: ${response.body}');
        return true;
      }
      return false;
    } catch (e) {
      print('Gagal kirim user ke MySQL: $e');
      return false;
    }
  }
}
