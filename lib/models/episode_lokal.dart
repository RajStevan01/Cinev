// lib/models/episode_lokal.dart

class EpisodeLokal {
  final int id;
  final int movieId;
  final int episodeNumber;
  final String title;
  final String videoUrl;

  EpisodeLokal({
    required this.id,
    required this.movieId,
    required this.episodeNumber,
    required this.title,
    required this.videoUrl,
  });

  factory EpisodeLokal.fromJson(Map<String, dynamic> json) {
    return EpisodeLokal(
      id: json['id'],
      movieId: json['movie_id'],
      episodeNumber: json['episode_number'],
      title: json['title'],
      videoUrl: json['video_url'],
    );
  }
}
