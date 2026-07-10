<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

$ip_server = '10.222.15.55';
$base_url = "http://$ip_server/cinev_api/banners/";
$target_dir = "../cinev_api/banners/";

if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $judul = $conn->real_escape_string($_POST['judul'] ?? 'Banner');
    $posisi = $conn->real_escape_string($_POST['posisi'] ?? 'home');
    $link_url = isset($_POST['link_url']) && !empty($_POST['link_url']) ? $conn->real_escape_string($_POST['link_url']) : null;
    
    $file = $_FILES['file_banner'];
    if ($file['error'] === 0) {
        $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
        $filename = uniqid('banner_') . '.' . $ext;
        $target_file = $target_dir . $filename;

        if (move_uploaded_file($file['tmp_name'], $target_file)) {
            $path_gambar = $base_url . $filename;
            
            $stmt = $conn->prepare("INSERT INTO tb_banners (judul, path_gambar, posisi, link_url) VALUES (?, ?, ?, ?)");
            $stmt->bind_param("ssss", $judul, $path_gambar, $posisi, $link_url);
            
            if ($stmt->execute()) {
                $_SESSION['pesan'] = "Banner berhasil diunggah!";
            } else {
                $_SESSION['pesan'] = "Gagal menyimpan ke database.";
            }
            $stmt->close();
        } else {
            $_SESSION['pesan'] = "Gagal mengunggah file gambar.";
        }
    } else {
        $_SESSION['pesan'] = "Terjadi kesalahan saat mengunggah file.";
    }
}

header("Location: banners.php");
exit;
?>
