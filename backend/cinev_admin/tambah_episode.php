<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

// Fungsi notifikasi sama dengan tambah.php (tidak di-include untuk ringkas, asumsikan kita tulis sederhana)
function send_fcm_notification($title, $body) {
    // Bisa disalin dari tambah.php nanti, untuk sekarang biarkan minimal atau kita require jika ada helpers
    // Karena ini file terpisah, kita copy fungsi fcm dari tambah.php
    $credentials_path = 'firebase_credentials.json';
    if (!file_exists($credentials_path)) return false;
    
    $json = file_get_contents($credentials_path);
    $credentials = json_decode($json, true);
    
    $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
    $now = time();
    $payload = json_encode([
        'iss' => $credentials['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $now + 3600,
        'iat' => $now
    ]);
    
    $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
    $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
    
    $signature = '';
    openssl_sign($base64UrlHeader . "." . $base64UrlPayload, $signature, $credentials['private_key'], "sha256WithRSAEncryption");
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    $jwt = $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    curl_close($ch);
    
    $data = json_decode($response, true);
    $access_token = $data['access_token'] ?? null;
    $project_id = $credentials['project_id'] ?? null;

    if (!$access_token) return false;
    
    $url = 'https://fcm.googleapis.com/v1/projects/' . $project_id . '/messages:send';
    $message = [
        'message' => [
            'topic' => 'all_users',
            'notification' => [
                'title' => $title,
                'body' => $body
            ]
        ]
    ];
    $headers = [
        'Authorization: Bearer ' . $access_token,
        'Content-Type: application/json'
    ];
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
    $result = curl_exec($ch);
    curl_close($ch);
    return $result;
}

if (!isset($_GET['movie_id'])) {
    header("Location: index.php");
    exit;
}

$movie_id = (int)$_GET['movie_id'];
$stmt = $conn->prepare("SELECT * FROM tb_local_movies WHERE id = ?");
$stmt->bind_param("i", $movie_id);
$stmt->execute();
$movie = $stmt->get_result()->fetch_assoc();

if (!$movie) {
    header("Location: index.php");
    exit;
}

$msg = '';
if (isset($_POST['simpan'])) {
    $episode_number = (int)$_POST['episode_number'];
    $title = $conn->real_escape_string($_POST['title']);
    
    $video_url = '';
    $upload_dir = 'uploads/';
    $host = "musky-credit-guru.ngrok-free.dev";
    $protocol = "https";
    $base_url = "$protocol://$host/cinev_admin/uploads/";

    if (isset($_FILES['video']) && $_FILES['video']['error'] == 0) {
        $video_name = time() . '_episode_' . $_FILES['video']['name'];
        if (move_uploaded_file($_FILES['video']['tmp_name'], $upload_dir . $video_name)) {
            $video_url = $base_url . $video_name;
        }
    }

    if ($video_url != '') {
        $sql = "INSERT INTO tb_local_episodes (movie_id, episode_number, title, video_url) 
                VALUES ('$movie_id', '$episode_number', '$title', '$video_url')";
        
        if ($conn->query($sql) === TRUE) {
            // INSERT ke tb_notifications (Lonceng Notifikasi)
            $judulNotif = "Episode Baru: " . $movie['title'];
            $pesanNotif = "Episode $episode_number ($title) sudah rilis. Yuk tonton sekarang!";
            $pesanNotifDB = $conn->real_escape_string($pesanNotif);
            date_default_timezone_set('Asia/Jakarta');
            $waktu = date('Y-m-d H:i:s');
            
            $sql_notif = "INSERT INTO tb_notifications (kategori, judul, pesan, waktu) VALUES ('fcm', '$judulNotif', '$pesanNotifDB', '$waktu')";
            $conn->query($sql_notif);
            
            // Kirim Push Notif
            send_fcm_notification($judulNotif, $pesanNotif);

            header("Location: episodes.php?movie_id=" . $movie_id);
            exit;
        } else {
            $msg = 'Gagal menyimpan ke database: ' . $conn->error;
        }
    } else {
        $msg = 'Gagal mengupload file video!';
    }
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tambah Episode - <?= htmlspecialchars($movie['title']) ?></title>
    <link href="assets/css/style.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar">
        <a class="navbar-brand" href="index.php">Cinev Admin</a>
        <ul class="navbar-nav">
            <li><a class="nav-link" href="index.php">Film Lokal</a></li>
            <li><a class="nav-link" href="avatars.php">Manajemen Avatar</a></li>
            <li><a class="nav-link" href="banners.php">Manajemen Banner</a></li>
            <li><a class="nav-link" href="users.php">Manajemen User</a></li>
        </ul>
        <div class="nav-user">
            <span>Halo, <?= $_SESSION['admin'] ?></span>
            <a href="logout.php" class="btn btn-outline btn-sm">Logout</a>
        </div>
    </nav>

    <div class="container">
        <div class="header-actions">
            <div>
                <h2>Tambah Episode Baru</h2>
                <h4 style="color: var(--primary-color);">Series: <?= htmlspecialchars($movie['title']) ?></h4>
            </div>
            <a href="episodes.php?movie_id=<?= $movie_id ?>" class="btn btn-outline">Kembali</a>
        </div>
        
        <?php if($msg): ?>
            <div class="alert alert-danger"><?= $msg ?></div>
        <?php endif; ?>

        <form method="POST" enctype="multipart/form-data" class="glass-panel" style="max-width: 800px; margin: 0 auto;">
            <div class="form-group">
                <label class="form-label">Nomor Episode</label>
                <input type="number" name="episode_number" class="form-control" required>
            </div>
            <div class="form-group">
                <label class="form-label">Judul Episode (Contoh: Awal Mula)</label>
                <input type="text" name="title" class="form-control" required>
            </div>
            <div class="form-group" style="margin-bottom: 0;">
                <label class="form-label">Upload Video (MP4)</label>
                <input type="file" name="video" accept="video/mp4" class="form-control" required>
            </div>
            <button type="submit" name="simpan" class="btn btn-primary" style="width: 100%; margin-top: 1rem;">Simpan Episode</button>
        </form>
    </div>
</body>
</html>
