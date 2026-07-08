<?php
require 'koneksi.php';

// 1. Membuat tabel tb_admin
$sqlAdmin = "CREATE TABLE IF NOT EXISTS tb_admin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)";

if ($conn->query($sqlAdmin) === TRUE) {
    echo "Tabel tb_admin berhasil dibuat.\n";
    
    // Insert default admin jika belum ada
    $checkAdmin = $conn->query("SELECT * FROM tb_admin WHERE username='admin'");
    if($checkAdmin->num_rows == 0) {
        $hashedPass = password_hash('admin123', PASSWORD_DEFAULT);
        $conn->query("INSERT INTO tb_admin (username, password) VALUES ('admin', '$hashedPass')");
        echo "Default admin (admin/admin123) berhasil ditambahkan.\n";
    }
} else {
    echo "Gagal membuat tb_admin: " . $conn->error . "\n";
}

// 2. Membuat tabel tb_local_movies
// Disamakan dengan beberapa atribut TMDB agar mudah saat digabung di Flutter
$sqlMovies = "CREATE TABLE IF NOT EXISTS tb_local_movies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    overview TEXT,
    poster_path VARCHAR(255),
    backdrop_path VARCHAR(255),
    video_url VARCHAR(255) NOT NULL,
    release_date DATE,
    vote_average DECIMAL(3,1) DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)";

if ($conn->query($sqlMovies) === TRUE) {
    echo "Tabel tb_local_movies berhasil dibuat.\n";
} else {
    echo "Gagal membuat tb_local_movies: " . $conn->error . "\n";
}

$conn->close();
?>
