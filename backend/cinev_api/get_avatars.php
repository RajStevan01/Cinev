<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'koneksi.php';

$avatars = [];
$result = $conn->query("SELECT id, nama_avatar, path_gambar FROM tb_avatars ORDER BY created_at DESC");

if ($result) {
    while ($row = $result->fetch_assoc()) {
        $avatars[] = $row;
    }
}

echo json_encode([
    "status" => "success",
    "avatars" => $avatars
]);

$conn->close();
?>
