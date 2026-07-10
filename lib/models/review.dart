class Review {
  final String id;
  final String userUid;
  final String nama;
  final String photoUrl;
  final int idFilm;
  final int rating;
  final String komentar;
  final String waktuDibuat;

  Review({
    required this.id,
    required this.userUid,
    required this.nama,
    required this.photoUrl,
    required this.idFilm,
    required this.rating,
    required this.komentar,
    required this.waktuDibuat,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'].toString(),
      userUid: json['user_uid'] ?? '',
      nama: json['nama'] ?? 'Pengguna',
      photoUrl: json['photo_url'] ?? '',
      idFilm: int.tryParse(json['id_film'].toString()) ?? 0,
      rating: int.tryParse(json['rating'].toString()) ?? 0,
      komentar: json['komentar'] ?? '',
      waktuDibuat: json['waktu_dibuat'] ?? '',
    );
  }
}
