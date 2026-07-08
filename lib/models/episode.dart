// lib/models/episode.dart

class Episode {
  final String nama;
  final String ringkasan;
  final int nomorEpisode;
  final String? pathGambar; // Still image path

  Episode({
    required this.nama,
    required this.ringkasan,
    required this.nomorEpisode,
    this.pathGambar,
  });

  factory Episode.dariJson(Map<String, dynamic> json) {
    return Episode(
      nama: json['name'],
      ringkasan: json['overview'],
      nomorEpisode: json['episode_number'],
      pathGambar: json['still_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['still_path']}'
          : null,
    );
  }
}
