<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

// FUNGSI UNTUK GENERATE OAUTH2 TOKEN (HTTP v1 FCM)
function get_fcm_token() {
    $credentials_path = 'firebase_credentials.json';
    if (!file_exists($credentials_path)) return null;
    
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
    return [
        'access_token' => $data['access_token'] ?? null,
        'project_id' => $credentials['project_id'] ?? null
    ];
}

// FUNGSI MENGIRIM PUSH NOTIFIKASI
function send_fcm_notification($title, $body) {
    $auth = get_fcm_token();
    if (!$auth || !$auth['access_token']) return false;
    
    $access_token = $auth['access_token'];
    $project_id = $auth['project_id'];
    
    $url = 'https://fcm.googleapis.com/v1/projects/' . $project_id . '/messages:send';
    
    $message = [
        'message' => [
            'topic' => 'all_users', // Kita tembak ke topik 'all_users'
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


$msg = '';
if (isset($_POST['simpan'])) {
    $title = $conn->real_escape_string($_POST['title']);
    $overview = $conn->real_escape_string($_POST['overview']);
    $release_date = $_POST['release_date'];
    $vote_average = $_POST['vote_average'];

    // Inisialisasi variabel untuk path
    $poster_path = '';
    $backdrop_path = ''; // Sama dengan poster untuk simpelnya
    $video_url = '';
    
    $upload_dir = 'uploads/';
    // Gunakan IP dinamis dari server saat ini, jadi tidak perlu ganti manual kalau IP berubah
    $host = $_SERVER['HTTP_HOST'];
    $base_url = "http://$host/cinev_admin/uploads/";

    // Proses Upload Poster
    if (isset($_FILES['poster']) && $_FILES['poster']['error'] == 0) {
        $poster_name = time() . '_poster_' . $_FILES['poster']['name'];
        if (move_uploaded_file($_FILES['poster']['tmp_name'], $upload_dir . $poster_name)) {
            $poster_path = $base_url . $poster_name;
            $backdrop_path = $poster_path; 
        }
    }

    // Proses Upload Video
    if (isset($_FILES['video']) && $_FILES['video']['error'] == 0) {
        $video_name = time() . '_video_' . $_FILES['video']['name'];
        if (move_uploaded_file($_FILES['video']['tmp_name'], $upload_dir . $video_name)) {
            $video_url = $base_url . $video_name;
        }
    }

    if ($poster_path != '' && $video_url != '') {
        $sql = "INSERT INTO tb_local_movies (title, overview, poster_path, backdrop_path, video_url, release_date, vote_average) 
                VALUES ('$title', '$overview', '$poster_path', '$backdrop_path', '$video_url', '$release_date', '$vote_average')";
        
        if ($conn->query($sql) === TRUE) {
            // INSERT ke tb_notifications (Lonceng Notifikasi)
            $judulNotif = "Film Baru Ditambahkan!";
            $pesanNotif = "Film '$title' sudah bisa kamu tonton sekarang.";
            $pesanNotifDB = $conn->real_escape_string($pesanNotif); // Mencegah error tanda kutip
            date_default_timezone_set('Asia/Jakarta');
            $waktu = date('Y-m-d H:i:s');
            
            $sql_notif = "INSERT INTO tb_notifications (kategori, judul, pesan, waktu) VALUES ('fcm', '$judulNotif', '$pesanNotifDB', '$waktu')";
            $conn->query($sql_notif);
            
            // Kirim FCM Push Notification ke semua HP Flutter App
            send_fcm_notification($judulNotif, $pesanNotif);

            header("Location: index.php");
            exit;
        } else {
            $msg = 'Gagal menyimpan ke database: ' . $conn->error;
        }
    } else {
        $msg = 'Gagal mengupload file gambar atau video!';
    }
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tambah Film Lokal</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark mb-4">
        <div class="container">
            <a class="navbar-brand" href="index.php">Cinev Admin</a>
        </div>
    </nav>

    <div class="container">
        <h3>Tambah Film Baru</h3>
        <a href="index.php" class="btn btn-secondary mb-3">Kembali</a>
        
        <?php if($msg): ?>
            <div class="alert alert-danger"><?= $msg ?></div>
        <?php endif; ?>

        <form method="POST" enctype="multipart/form-data" class="bg-light p-4 border rounded">
            <div class="mb-3">
                <label class="form-label">Judul Film</label>
                <input type="text" name="title" class="form-control" required>
            </div>
            <div class="mb-3">
                <label class="form-label">Sinopsis (Overview)</label>
                <textarea name="overview" class="form-control" rows="4" required></textarea>
            </div>
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label class="form-label">Tanggal Rilis</label>
                    <input type="date" name="release_date" class="form-control" required>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Rating (1.0 - 10.0)</label>
                    <input type="number" step="0.1" name="vote_average" class="form-control" value="8.0" required>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label">Upload Poster (Image)</label>
                <input type="file" name="poster" accept="image/*" class="form-control" required>
            </div>
            <div class="mb-3">
                <label class="form-label">Upload Video Film (.mp4)</label>
                <input type="file" name="video" accept="video/mp4" class="form-control" required>
            </div>
            <button type="submit" name="simpan" class="btn btn-success w-100 mt-3">Simpan & Upload Film</button>
        </form>
    </div>
</body>
</html>
