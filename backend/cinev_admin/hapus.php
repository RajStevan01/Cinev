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
        
        if (file_exists("uploads/" . $poster_filename) && $poster_filename != "") unlink("uploads/" . $poster_filename);
        if (file_exists("uploads/" . $video_filename) && $video_filename != "") unlink("uploads/" . $video_filename);
        
        // Hapus file fisik dari episode-episode serial ini
        $episodes = $conn->query("SELECT video_url FROM tb_local_episodes WHERE movie_id = $id");
        if ($episodes->num_rows > 0) {
            while ($ep = $episodes->fetch_assoc()) {
                $ep_video = basename($ep['video_url']);
                if (file_exists("uploads/" . $ep_video) && $ep_video != "") {
                    unlink("uploads/" . $ep_video);
                }
            }
        }

        // Hapus dari database (tb_local_episodes otomatis terhapus karena ON DELETE CASCADE)
        $conn->query("DELETE FROM tb_local_movies WHERE id = $id");
    }
}
header("Location: index.php");
exit;
?>
