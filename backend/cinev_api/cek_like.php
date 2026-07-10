<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'koneksi.php';

$user_uid = $_GET['user_uid'] ?? '';
$id_film = $_GET['id_film'] ?? '';

if (empty($id_film)) {
    echo json_encode(["status" => "error", "message" => "ID Film tidak boleh kosong"]);
    exit;
}

$id_film = (int)$id_film;
$is_liked = false;

// Jika user login, cek apakah user sudah melike film ini
if (!empty($user_uid)) {
    $check_sql = "SELECT id FROM tb_likes WHERE user_uid = ? AND id_film = ?";
    $stmt = $conn->prepare($check_sql);
    $stmt->bind_param("si", $user_uid, $id_film);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        $is_liked = true;
    }
}

// Hitung total like untuk film ini
$count_sql = "SELECT COUNT(id) as total_likes FROM tb_likes WHERE id_film = ?";
$stmt_count = $conn->prepare($count_sql);
$stmt_count->bind_param("i", $id_film);
$stmt_count->execute();
$count_result = $stmt_count->get_result()->fetch_assoc();

echo json_encode([
    "status" => "success",
    "is_liked" => $is_liked,
    "total_likes" => (int)$count_result['total_likes']
]);

$conn->close();
?>
