<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

if (isset($_GET['id'])) {
    $id = (int)$_GET['id'];
    
    // Ambil path gambar untuk dihapus dari direktori
    $stmt = $conn->prepare("SELECT path_gambar FROM tb_avatars WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $path_gambar = $row['path_gambar'];
        
        // Ekstrak nama file dari URL
        // Contoh: http://10.222.15.55/cinev_api/avatars/avatar_123.jpg
        $filename = basename($path_gambar);
        $file_path = "../cinev_api/avatars/" . $filename;
        
        if (file_exists($file_path)) {
            unlink($file_path);
        }
        
        // Hapus dari database
        $stmt_del = $conn->prepare("DELETE FROM tb_avatars WHERE id = ?");
        $stmt_del->bind_param("i", $id);
        if ($stmt_del->execute()) {
            $_SESSION['pesan'] = "Avatar berhasil dihapus!";
        } else {
            $_SESSION['pesan'] = "Gagal menghapus dari database.";
        }
        $stmt_del->close();
    } else {
        $_SESSION['pesan'] = "Avatar tidak ditemukan.";
    }
    $stmt->close();
}

header("Location: avatars.php");
exit;
?>
