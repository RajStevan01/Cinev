<?php
require 'koneksi.php';

header('Content-Type: application/json');

$user_uid = isset($_GET['user_uid']) ? $conn->real_escape_string($_GET['user_uid']) : '';

// Ambil notifikasi global ('all') dan milik user ini
$sql = "SELECT * FROM tb_notifications WHERE user_uid = 'all' OR user_uid = '$user_uid' ORDER BY waktu DESC";
$result = $conn->query($sql);

$data = array();
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
}

echo json_encode($data);
?>
