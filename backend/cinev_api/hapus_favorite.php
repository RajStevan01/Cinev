<?php
require 'koneksi.php';

$id = $_POST['id'] ?? '';
$user_uid = $_POST['user_uid'] ?? '';

$query = "DELETE FROM favorite WHERE id = '$id' AND user_uid = '$user_uid'";

if ($conn->query($query) === TRUE) {
    echo json_encode(["status" => "success", "message" => "Berhasil dihapus dari favorit"]);
} else {
    echo json_encode(["status" => "error", "message" => "Gagal: " . $conn->error]);
}
?>
