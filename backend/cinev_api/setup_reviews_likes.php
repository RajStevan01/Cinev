<?php
include 'koneksi.php';

// Tabel tb_reviews
$sql_reviews = "CREATE TABLE IF NOT EXISTS tb_reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_uid VARCHAR(100) NOT NULL,
    id_film INT NOT NULL,
    rating INT NOT NULL CHECK(rating >= 1 AND rating <= 5),
    komentar TEXT,
    waktu_dibuat DATETIME DEFAULT CURRENT_TIMESTAMP
)";

if ($conn->query($sql_reviews) === TRUE) {
    echo "Tabel tb_reviews berhasil dibuat atau sudah ada.<br>";
} else {
    echo "Error membuat tabel tb_reviews: " . $conn->error . "<br>";
}

// Tabel tb_likes
$sql_likes = "CREATE TABLE IF NOT EXISTS tb_likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_uid VARCHAR(100) NOT NULL,
    id_film INT NOT NULL,
    UNIQUE KEY (user_uid, id_film)
)";

if ($conn->query($sql_likes) === TRUE) {
    echo "Tabel tb_likes berhasil dibuat atau sudah ada.<br>";
} else {
    echo "Error membuat tabel tb_likes: " . $conn->error . "<br>";
}

$conn->close();
?>
