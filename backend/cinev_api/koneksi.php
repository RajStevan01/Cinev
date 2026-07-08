<?php
// Mengizinkan aplikasi Flutter kita mengakses API ini tanpa diblokir (CORS)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE, PUT");
header("Access-Control-Allow-Headers: Content-Type");

$host = "localhost"; // Karena servernya di laptop sendiri
$user = "root";      // Username default XAMPP
$pass = "";          // Password default XAMPP (kosong)
$db   = "cinev_db";  // Nama database yang baru kamu buat

// Membuka gerbang koneksi
$conn = new mysqli($host, $user, $pass, $db);

// Mengecek jika koneksi gagal
if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => "Koneksi database gagal: " . $conn->connect_error
    ]));
}
?>