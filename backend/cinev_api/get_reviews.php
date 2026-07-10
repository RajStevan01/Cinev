<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'koneksi.php';

$id_film = $_GET['id_film'] ?? '';

if (empty($id_film)) {
    echo json_encode(["status" => "error", "message" => "ID Film tidak boleh kosong"]);
    exit;
}

$id_film = (int)$id_film;

// Ambil rata-rata rating
$avg_sql = "SELECT AVG(rating) as average_rating, COUNT(id) as total_reviews FROM tb_reviews WHERE id_film = ?";
$stmt_avg = $conn->prepare($avg_sql);
$stmt_avg->bind_param("i", $id_film);
$stmt_avg->execute();
$avg_result = $stmt_avg->get_result()->fetch_assoc();

// Ambil 10 ulasan terbaru
$reviews_sql = "SELECT r.*, u.username as nama, u.photo_url FROM tb_reviews r 
                LEFT JOIN users u ON r.user_uid = u.uid 
                WHERE r.id_film = ? 
                ORDER BY r.waktu_dibuat DESC LIMIT 10";
$stmt_reviews = $conn->prepare($reviews_sql);
$stmt_reviews->bind_param("i", $id_film);
$stmt_reviews->execute();
$reviews_result = $stmt_reviews->get_result();

$reviews = [];
while ($row = $reviews_result->fetch_assoc()) {
    $reviews[] = $row;
}

echo json_encode([
    "status" => "success",
    "average_rating" => $avg_result['average_rating'] ? (double)$avg_result['average_rating'] : 0,
    "total_reviews" => (int)$avg_result['total_reviews'],
    "reviews" => $reviews
]);

$conn->close();
?>
