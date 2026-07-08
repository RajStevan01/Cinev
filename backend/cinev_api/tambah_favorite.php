<?php
error_reporting(0); // Matikan error bawaan HTML
date_default_timezone_set('Asia/Jakarta');
require 'koneksi.php';

$id = $_POST['id'] ?? '';
$user_uid = $_POST['user_uid'] ?? '';
$nama = $_POST['nama'] ?? '';
$pathPoster = $_POST['pathPoster'] ?? '';
$tanggal = $_POST['tanggalDitambahkan'] ?? date('Y-m-d H:i:s');

if(empty($id) || empty($user_uid)) {
    echo json_encode(["status" => "error", "message" => "ID Film atau UID User kosong!"]);
    exit;
}

// Gunakan try-catch agar jika MySQL error, outputnya tetap berupa JSON
try {
    $query = "REPLACE INTO favorite (id, user_uid, nama, pathPoster, tanggalDitambahkan) 
              VALUES ('$id', '$user_uid', '$nama', '$pathPoster', '$tanggal')";

    if ($conn->query($query) === TRUE) {
        echo json_encode(["status" => "success", "message" => "Berhasil ditambahkan ke favorit"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Gagal: " . $conn->error]);
    }
} catch (Exception $e) {
    // Tangkap fatal error SQL dan kembalikan sebagai JSON
    echo json_encode(["status" => "error", "message" => "Database Error: " . $e->getMessage()]);
}
?>
