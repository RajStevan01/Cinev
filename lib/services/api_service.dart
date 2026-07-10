// lib/services/api_service.dart

import 'dart:convert';
import 'package:aplikasi_mobile/models/serial_tv.dart';
import 'package:http/http.dart' as http;
import 'package:aplikasi_mobile/models/episode.dart';
import 'package:aplikasi_mobile/services/database_helper.dart';
import 'package:aplikasi_mobile/models/episode_lokal.dart';

class ApiService {
  static const String _apiKey =
      '6216bc7da3a53fd24c9cb97e899e2706'; // PASTIKAN API KEY BENAR
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  // Fungsi untuk mengambil daftar TV Series berdasarkan kategori
  Future<List<SerialTv>> ambilDaftarSerialTv(String kategori) async {
    String endpoint;
    switch (kategori) {
      case 'rating_tertinggi':
        endpoint = '/tv/top_rated';
        break;
      case 'populer':
        endpoint = '/tv/popular';
        break;
      default:
        throw Exception('Kategori tidak valid');
    }

    final url = Uri.parse('$_baseUrl$endpoint?api_key=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results = data['results'];
        List<SerialTv> daftarSerial = results
            .map((json) => SerialTv.dariJsonList(json))
            .toList();
        return daftarSerial;
      } else {
        throw Exception(
          'Gagal memuat daftar serial TV: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Fungsi untuk mengambil data detail satu TV Series
  Future<SerialTv> ambilDetailSerialTv(int idSerial) async {
    final url = Uri.parse('$_baseUrl/tv/$idSerial?api_key=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SerialTv.dariJsonDetail(data);
      } else {
        throw Exception(
          'Gagal memuat detail serial TV: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Fungsi untuk mengambil daftar episode dari season tertentu
  Future<List<Episode>> ambilDaftarEpisode(
    int idSerial,
    int nomorSeason,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/tv/$idSerial/season/$nomorSeason?api_key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Data episode ada di dalam key 'episodes'
        List<dynamic> results = data['episodes'];
        List<Episode> daftarEpisode = results
            .map((json) => Episode.dariJson(json))
            .toList();
        return daftarEpisode;
      } else {
        throw Exception('Gagal memuat daftar episode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<String?> ambilLinkTrailer(int idSerial) async {
    final url = Uri.parse('$_baseUrl/tv/$idSerial/videos?api_key=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results = data['results'];

        // Cari video yang tipenya "Trailer" dan situsnya "YouTube"
        var trailer = results.firstWhere(
          (video) => video['type'] == 'Trailer' && video['site'] == 'YouTube',
          orElse: () => null, // Jika tidak ada trailer, kembalikan null
        );

        if (trailer != null) {
          return trailer['key']; // 'key' ini adalah ID video YouTube
        }
      }
      return null; // Kembalikan null jika tidak ada trailer atau error
    } catch (e) {
      throw Exception('Gagal mengambil trailer: $e');
    }
  }

  Future<List<String>> ambilTrendingKeywords() async {
    final url = Uri.parse('$_baseUrl/trending/tv/day?api_key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results = data['results'];
        // Ambil 3-5 judul teratas dan jadikan keyword
        return results
            .take(3) // Ambil 3 item teratas
            .map((item) => item['name'] as String)
            .toList();
      } else {
        return []; // Kembalikan list kosong jika gagal
      }
    } catch (e) {
      return [];
    }
  }

  // FUNGSI BARU 2: Logika pencarian "pintar" (Broad Search)
  Future<List<SerialTv>> cariSerialTv(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final keywords = query.trim().split(' ');
    List<Future<List<SerialTv>>> futures = [];
    
    // 1. Pencarian TMDB
    for (var keyword in keywords) {
      if (keyword.isNotEmpty) {
        final url = Uri.parse(
          '$_baseUrl/search/tv?api_key=$_apiKey&query=$keyword',
        );
        futures.add(
          http.get(url).then((response) {
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              List<dynamic> results = data['results'];
              return results
                  .map((json) => SerialTv.dariJsonList(json))
                  .toList();
            } else {
              return <SerialTv>[];
            }
          }),
        );
      }
    }

    // 2. Pencarian Film Lokal
    futures.add(
      ambilSerialTvLokal().then((localMovies) {
        return localMovies.where((movie) => 
          movie.nama.toLowerCase().contains(query.toLowerCase())
        ).toList();
      })
    );

    // 3. Tunggu semua selesai
    final resultsOfLists = await Future.wait(futures);

    // 4. Gabungkan tanpa duplikat
    final Map<int, SerialTv> uniqueResults = {};
    for (var list in resultsOfLists) {
      for (var serial in list) {
        uniqueResults[serial.id] = serial;
      }
    }

    // 5. Film lokal ditaruh paling depan
    final semuaFilm = uniqueResults.values.toList();
    semuaFilm.sort((a, b) {
      if (a.isLokal && !b.isLokal) return -1;
      if (!a.isLokal && b.isLokal) return 1;
      return 0;
    });

    return semuaFilm;
  }

  // FUNGSI BARU 3: Mengambil film lokal dari XAMPP
  Future<List<SerialTv>> ambilSerialTvLokal() async {
    final url = Uri.parse('${DatabaseHelper.baseUrl}/get_local_movies.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results = data['results'];
        return results.map((json) => SerialTv.dariJsonLokal(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error ambilSerialTvLokal: $e');
      return [];
    }
  }

  // FUNGSI BARU 4: Mengambil episode lokal untuk sebuah series
  Future<List<EpisodeLokal>> ambilEpisodeLokal(int movieId) async {
    final url = Uri.parse('${DatabaseHelper.baseUrl}/get_episodes.php?movie_id=$movieId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> results = data['episodes'];
          return results.map((json) => EpisodeLokal.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error ambilEpisodeLokal: $e');
      return [];
    }
  }
}
