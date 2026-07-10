<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

if (isset($_GET['id']) && isset($_GET['movie_id'])) {
    $id = (int)$_GET['id'];
    $movie_id = (int)$_GET['movie_id'];

    $result = $conn->query("SELECT video_url FROM tb_local_episodes WHERE id = $id");
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $video_url = $row['video_url'];
        $video_name = basename($video_url);

        // Hapus file fisik
        if (file_exists("uploads/" . $video_name) && $video_name != "") {
            unlink("uploads/" . $video_name);
        }

        // Hapus dari database
        $conn->query("DELETE FROM tb_local_episodes WHERE id = $id");
    }

    header("Location: episodes.php?movie_id=" . $movie_id);
    exit;
} else {
    header("Location: index.php");
    exit;
}
?>
