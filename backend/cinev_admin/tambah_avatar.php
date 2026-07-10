<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

// Menentukan URL dasar agar path_gambar menggunakan IP/domain yang benar
$host = "musky-credit-guru.ngrok-free.dev";
$protocol = "https";
$base_url = "$protocol://$host/cinev_api/avatars/";

// Direktori fisik penyimpanan di htdocs
$target_dir = "../cinev_api/avatars/";
if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $nama_avatar = isset($_POST['nama_avatar']) ? $conn->real_escape_string($_POST['nama_avatar']) : 'Avatar';
    if(empty($nama_avatar)) $nama_avatar = 'Avatar';

    $file = $_FILES['file_avatar'];
    if ($file['error'] === 0) {
        $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
        $filename = uniqid('avatar_') . '.' . $ext;
        $target_file = $target_dir . $filename;

        // Validasi tipe file
        $allowed = ['jpg', 'jpeg', 'png'];
        if (in_array(strtolower($ext), $allowed)) {
            if (move_uploaded_file($file['tmp_name'], $target_file)) {
                $path_gambar = $base_url . $filename;
                
                $stmt = $conn->prepare("INSERT INTO tb_avatars (nama_avatar, path_gambar) VALUES (?, ?)");
                $stmt->bind_param("ss", $nama_avatar, $path_gambar);
                
                if ($stmt->execute()) {
                    $_SESSION['pesan'] = "Avatar berhasil diunggah!";
                } else {
                    $_SESSION['pesan'] = "Gagal menyimpan ke database.";
                }
                $stmt->close();
            } else {
                $_SESSION['pesan'] = "Gagal mengunggah file gambar.";
            }
        } else {
            $_SESSION['pesan'] = "Format file tidak didukung. Hanya JPG/PNG.";
        }
    } else {
        $_SESSION['pesan'] = "Terjadi kesalahan saat mengunggah file.";
    }
}

header("Location: avatars.php");
exit;
?>
