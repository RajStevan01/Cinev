<?php
require 'koneksi.php';

$id = $_GET['id'] ?? '';
$user_uid = $_GET['user_uid'] ?? '';

$query = "SELECT * FROM favorite WHERE id = '$id' AND user_uid = '$user_uid'";
$result = $conn->query($query);

// Jika baris data ditemukan, berarti isFavorite = true
if ($result->num_rows > 0) {
    echo json_encode(["isFavorite" => true]);
} else {
    echo json_encode(["isFavorite" => false]);
}
?>
