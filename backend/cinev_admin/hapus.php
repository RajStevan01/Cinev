<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

if (isset($_GET['id'])) {
    $id = (int)$_GET['id'];
    
    // Ambil data dulu untuk menghapus file fisiknya
    $result = $conn->query("SELECT * FROM tb_local_movies WHERE id = $id");
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        
        // Hapus file dari folder (path yang tersimpan berupa URL penuh, jadi harus dipotong)
        $poster_filename = basename($row['poster_path']);
        $video_filename = basename($row['video_url']);
        
        if (file_exists("uploads/" . $poster_filename)) unlink("uploads/" . $poster_filename);
        if (file_exists("uploads/" . $video_filename)) unlink("uploads/" . $video_filename);
        
        // Hapus dari database
        $conn->query("DELETE FROM tb_local_movies WHERE id = $id");
    }
}
header("Location: index.php");
exit;
?>
