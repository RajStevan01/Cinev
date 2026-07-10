<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'koneksi.php';

$banners_home = [];
$banners_player = [];

$sql = "SELECT id, judul, path_gambar, posisi, link_url FROM tb_banners ORDER BY created_at DESC";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        if ($row['posisi'] === 'home') {
            $banners_home[] = $row;
        } elseif ($row['posisi'] === 'player') {
            $banners_player[] = $row;
        }
    }
}

echo json_encode([
    "status" => "success",
    "data" => [
        "home" => $banners_home,
        "player" => $banners_player
    ]
]);

$conn->close();
?>
