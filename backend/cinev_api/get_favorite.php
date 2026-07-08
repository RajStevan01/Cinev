<?php
require 'koneksi.php';

$user_uid = $_GET['user_uid'] ?? '';

if(empty($user_uid)) {
    echo json_encode([]); // Kembalikan list kosong jika tidak ada UID
    exit;
}

// Ambil data khusus milik user tersebut, urutkan dari yang terbaru
$query = "SELECT * FROM favorite WHERE user_uid = '$user_uid' ORDER BY tanggalDitambahkan DESC";
$result = $conn->query($query);

$data = [];
while($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode($data);
?>
