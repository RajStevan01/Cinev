// lib/models/serial_tv.dart

class SerialTv {
  final int id;
  final String nama; // Dulu 'title', sekarang 'name'
  final String ringkasan; // Dulu 'overview'
  final String pathPoster; // Dulu 'posterPath'
  final double rataRataSuara; // Dulu 'voteAverage'
  final String? pathLatar; // Tambahan untuk halaman detail
  final List<dynamic>? genre; // Tambahan untuk halaman detail
  final int? durasiEpisode; // Tambahan untuk halaman detail
  final String? tanggalRilisPertama; // Tambahan untuk halaman detail
  final int? jumlahSeason;
  final bool isLokal; // Penanda apakah ini film lokal
  final String? urlVideoLokal; // URL video mp4 lokal
  final int? progressSeconds; // Tambahan untuk history
  final int? totalSeconds; // Tambahan untuk history

  SerialTv({
    required this.id,
    required this.nama,
    required this.ringkasan,
    required this.pathPoster,
    required this.rataRataSuara,
    this.pathLatar,
    this.genre,
    this.durasiEpisode,
    this.tanggalRilisPertama,
    this.jumlahSeason,
    this.isLokal = false,
    this.urlVideoLokal,
    this.progressSeconds,
    this.totalSeconds,
  });

  // Factory method untuk membuat instance dari JSON list (dari Top Rated/Popular)
  factory SerialTv.dariJsonList(Map<String, dynamic> json) {
    return SerialTv(
      id: json['id'],
      nama: json['name'] ?? json['title'] ?? 'Tanpa Judul',
      ringkasan: json['overview'] ?? '',
      pathPoster: 'https://image.tmdb.org/t/p/w500${json['poster_path']}',
      rataRataSuara: (json['vote_average'] as num).toDouble(),
    );
  }

  // Factory method untuk film lokal
  factory SerialTv.dariJsonLokal(Map<String, dynamic> json) {
    return SerialTv(
      id: json['id'],
      nama: json['title'] ?? 'Tanpa Judul',
      ringkasan: json['overview'] ?? '',
      pathPoster: json['poster_path'] ?? '', // Langsung URL penuh
      rataRataSuara: (json['vote_average'] as num).toDouble(),
      pathLatar: json['backdrop_path'] ?? '',
      tanggalRilisPertama: json['release_date'],
      isLokal: true,
      urlVideoLokal: json['video_url'],
      progressSeconds: json['progress_seconds'] != null ? int.tryParse(json['progress_seconds'].toString()) : null,
      totalSeconds: json['total_seconds'] != null ? int.tryParse(json['total_seconds'].toString()) : null,
    );
  }

  // Factory method untuk membuat instance dari JSON detail (dari halaman detail)
  factory SerialTv.dariJsonDetail(Map<String, dynamic> json) {
    return SerialTv(
      id: json['id'],
      nama: json['name'] ?? json['title'] ?? 'Tanpa Judul',
      ringkasan: json['overview'] ?? '',
      pathPoster: 'https://image.tmdb.org/t/p/w500${json['poster_path']}',
      rataRataSuara: (json['vote_average'] as num).toDouble(),
      pathLatar: 'https://image.tmdb.org/t/p/w780${json['backdrop_path']}',
      genre: json['genres'],
      // Ambil durasi dari episode pertama jika ada
      durasiEpisode:
          json['episode_run_time'] != null &&
              json['episode_run_time'].isNotEmpty
          ? json['episode_run_time'][0]
          : null,
      tanggalRilisPertama: json['first_air_date'],
      jumlahSeason: json['number_of_seasons'],
    );
  }
}
