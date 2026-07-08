<?php
error_reporting(0); // Matikan error bawaan HTML agar JSON aman
date_default_timezone_set('Asia/Jakarta'); // Set zona waktu
require 'koneksi.php';

// Menangkap data yang dikirim dari Flutter
$uid = $_POST['uid'] ?? '';
$nama = $_POST['nama'] ?? '';
$email = $_POST['email'] ?? '';

// Validasi sederhana
if(empty($uid) || empty($email)) {
    echo json_encode(["status" => "error", "message" => "UID atau Email kosong!"]);
    exit;
}

// Gunakan REPLACE INTO agar:
// - Jika UID belum ada (Register) -> Insert data baru
// - Jika UID sudah ada (Login) -> Update/Timpa data lama (mencegah error Duplicate Entry)
try {
    // Kita tangkap 'nama' dari Flutter, tapi kita masukkan ke kolom 'username' di MySQL
    // Dan kita tidak memasukkan tanggal_daftar karena kolomnya tidak ada di tabelmu
    $query = "REPLACE INTO users (uid, username, email) 
              VALUES ('$uid', '$nama', '$email')";

    if ($conn->query($query) === TRUE) {
        echo json_encode(["status" => "success", "message" => "Data user berhasil diamankan ke MySQL"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Gagal menyimpan: " . $conn->error]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Database Error: " . $e->getMessage()]);
}

?>