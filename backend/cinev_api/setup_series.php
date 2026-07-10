<?php
require 'koneksi.php';

echo "Memulai setup tabel series...<br>";

// 1. Tambahkan kolom type ke tb_local_movies jika belum ada
$checkTypeCol = $conn->query("SHOW COLUMNS FROM tb_local_movies LIKE 'type'");
if ($checkTypeCol->num_rows == 0) {
    $alterMovies = "ALTER TABLE tb_local_movies ADD COLUMN type ENUM('movie', 'series') DEFAULT 'movie' AFTER vote_average";
    if ($conn->query($alterMovies) === TRUE) {
        echo "Kolom 'type' berhasil ditambahkan ke tb_local_movies.<br>";
    } else {
        echo "Gagal menambahkan kolom type: " . $conn->error . "<br>";
    }
} else {
    echo "Kolom 'type' sudah ada di tb_local_movies.<br>";
}

// 2. Buat tabel tb_local_episodes
$createEpisodesTable = "
CREATE TABLE IF NOT EXISTS tb_local_episodes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    movie_id INT NOT NULL,
    episode_number INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    video_url VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (movie_id) REFERENCES tb_local_movies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

if ($conn->query($createEpisodesTable) === TRUE) {
    echo "Tabel 'tb_local_episodes' berhasil dibuat/sudah ada.<br>";
} else {
    echo "Gagal membuat tabel tb_local_episodes: " . $conn->error . "<br>";
}

echo "Setup selesai!";
?>
