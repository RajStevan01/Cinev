import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';

class DatabaseHelper {
  // Tetap menggunakan Singleton agar tidak perlu ubah cara panggil di file lain
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  DatabaseHelper._init();

  // PENTING: Atur Base URL sesuai dengan perangkamu!
  // - Jika pakai Emulator Android: 'http://10.0.2.2/cinev_api'
  // - Jika pakai HP Fisik/Real Device: IP Address WiFi laptopmu (contoh: 'http://192.168.1.15/cinev_api')
  static const String baseUrl = 'http://10.222.15.55/cinev_api';

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
  // ---------------- LIKES ---------------- //

  Future<Map<String, dynamic>> toggleLike(String userUid, int idFilm) async {
    final url = Uri.parse('$baseUrl/toggle_like.php');
    try {
      final response = await http.post(
        url,
        body: {
          'user_uid': userUid,
          'id_film': idFilm.toString(),
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'message': 'Gagal koneksi'};
    } catch (e) {
      print('Error toggleLike: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> cekStatusLike(String userUid, int idFilm) async {
    final url = Uri.parse('$baseUrl/cek_like.php?user_uid=$userUid&id_film=$idFilm');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'is_liked': false, 'total_likes': 0};
    } catch (e) {
      print('Error cekStatusLike: $e');
      return {'status': 'error', 'is_liked': false, 'total_likes': 0};
    }
  }

  // ---------------- REVIEWS ---------------- //

  Future<Map<String, dynamic>> simpanReview(String userUid, int idFilm, int rating, String komentar) async {
    final url = Uri.parse('$baseUrl/simpan_review.php');
    try {
      final response = await http.post(
        url,
        body: {
          'user_uid': userUid,
          'id_film': idFilm.toString(),
          'rating': rating.toString(),
          'komentar': komentar,
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'message': 'Gagal koneksi'};
    } catch (e) {
      print('Error simpanReview: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> ambilReview(int idFilm) async {
    final url = Uri.parse('$baseUrl/get_reviews.php?id_film=$idFilm');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> reviewsData = data['reviews'];
          List<Review> reviews = reviewsData.map((json) => Review.fromJson(json)).toList();
          return {
            'status': 'success',
            'average_rating': data['average_rating'],
            'total_reviews': data['total_reviews'],
            'reviews': reviews,
          };
        }
      }
      return {'status': 'error', 'reviews': <Review>[]};
    } catch (e) {
      print('Error ambilReview: $e');
      return {'status': 'error', 'reviews': <Review>[]};
    }
  }

  // --- Fitur Manajemen Avatar ---

  Future<List<String>> ambilDaftarAvatar() async {
    final url = Uri.parse('$baseUrl/get_avatars.php');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> avatarsData = data['avatars'];
          // Ambil hanya path_gambar sebagai list string
          return avatarsData.map((e) => e['path_gambar'].toString()).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error ambilDaftarAvatar: $e');
      return [];
    }
  }

  Future<bool> updateProfilUser(String userUid, String? photoUrl, String? username) async {
    final url = Uri.parse('$baseUrl/update_profil.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_uid': userUid,
          'photo_url': photoUrl ?? '',
          'username': username ?? '',
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error updateProfilUser: $e');
      return false;
    }
  }

  // --- Fitur Manajemen Banner ---

  Future<Map<String, List<BannerModel>>> ambilDaftarBanner() async {
    final url = Uri.parse('$baseUrl/get_banners.php');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> homeData = data['data']['home'] ?? [];
          List<dynamic> playerData = data['data']['player'] ?? [];
          
          return {
            'home': homeData.map((e) => BannerModel.fromJson(e)).toList(),
            'player': playerData.map((e) => BannerModel.fromJson(e)).toList(),
          };
        }
      }
      return {'home': [], 'player': []};
    } catch (e) {
      print('Error ambilDaftarBanner: $e');
      return {'home': [], 'player': []};
    }
  }
}

class BannerModel {
  final int id;
  final String judul;
  final String pathGambar;
  final String posisi;
  final String? linkUrl;

  BannerModel({
    required this.id,
    required this.judul,
    required this.pathGambar,
    required this.posisi,
    this.linkUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: int.parse(json['id'].toString()),
      judul: json['judul'],
      pathGambar: json['path_gambar'],
      posisi: json['posisi'],
      linkUrl: json['link_url'],
    );
  }
}

