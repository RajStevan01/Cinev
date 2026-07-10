<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

if ($id > 0) {
    // Ambil data untuk hapus file fisik
    $stmt = $conn->prepare("SELECT path_gambar FROM tb_banners WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        
        // Hapus file fisik
        $file_name = basename($row['path_gambar']);
        $file_path = "../cinev_api/banners/" . $file_name;
        if (file_exists($file_path)) {
            unlink($file_path);
        }
        
        // Hapus dari database
        $del_stmt = $conn->prepare("DELETE FROM tb_banners WHERE id = ?");
        $del_stmt->bind_param("i", $id);
        $del_stmt->execute();
        
        $_SESSION['pesan'] = "Banner berhasil dihapus.";
    } else {
        $_SESSION['pesan'] = "Banner tidak ditemukan.";
    }
}

header("Location: banners.php");
exit;
?>
