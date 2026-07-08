<?php
require 'koneksi.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $kategori = $conn->real_escape_string($_POST['kategori']);
    $judul = $conn->real_escape_string($_POST['judul']);
    $pesan = $conn->real_escape_string($_POST['pesan']);
    $waktu = $conn->real_escape_string($_POST['waktu']);
    $user_uid = isset($_POST['user_uid']) ? $conn->real_escape_string($_POST['user_uid']) : 'all';

    $sql = "INSERT INTO tb_notifications (kategori, judul, pesan, waktu, user_uid) 
            VALUES ('$kategori', '$judul', '$pesan', '$waktu', '$user_uid')";
            
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "Notifikasi ditambahkan"]);
    } else {
        echo json_encode(["status" => "error", "message" => $conn->error]);
    }
}
?>
