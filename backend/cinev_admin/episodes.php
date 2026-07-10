<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

if (!isset($_GET['movie_id'])) {
    header("Location: index.php");
    exit;
}

$movie_id = (int)$_GET['movie_id'];

// Cek apakah film/series ada
$stmt = $conn->prepare("SELECT * FROM tb_local_movies WHERE id = ?");
$stmt->bind_param("i", $movie_id);
$stmt->execute();
$movie = $stmt->get_result()->fetch_assoc();

if (!$movie || $movie['type'] != 'series') {
    echo "Konten tidak ditemukan atau bukan sebuah series.";
    exit;
}

$episodes = $conn->query("SELECT * FROM tb_local_episodes WHERE movie_id = $movie_id ORDER BY episode_number ASC");
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kelola Episode - <?= htmlspecialchars($movie['title']) ?></title>
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
            <h2>Kelola Episode: <span style="color: var(--primary-color);"><?= htmlspecialchars($movie['title']) ?></span></h2>
            <div style="display: flex; gap: 1rem;">
                <a href="index.php" class="btn btn-outline">Kembali</a>
                <a href="tambah_episode.php?movie_id=<?= $movie_id ?>" class="btn btn-primary">Tambah Episode</a>
            </div>
        </div>
        
        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>Episode</th>
                        <th>Judul Episode</th>
                        <th>Video</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if($episodes->num_rows > 0): while($row = $episodes->fetch_assoc()): ?>
                    <tr>
                        <td style="font-weight: bold; font-size: 1.1rem; color: var(--primary-color);">Ep <?= $row['episode_number'] ?></td>
                        <td style="font-weight: 500; font-size: 1.05rem;"><?= htmlspecialchars($row['title']) ?></td>
                        <td>
                            <a href="<?= htmlspecialchars($row['video_url']) ?>" target="_blank" class="btn btn-sm btn-outline">Lihat Video</a>
                        </td>
                        <td>
                            <a href="hapus_episode.php?id=<?= $row['id'] ?>&movie_id=<?= $movie_id ?>" class="btn btn-sm btn-danger" onclick="return confirm('Yakin ingin menghapus episode ini?')">Hapus</a>
                        </td>
                    </tr>
                    <?php endwhile; else: ?>
                    <tr><td colspan="4" style="text-align: center; color: var(--text-muted); padding: 3rem;">Belum ada episode untuk series ini.</td></tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
