<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

$movies = $conn->query("SELECT * FROM tb_local_movies ORDER BY created_at DESC");
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Admin - Cinev</title>
    <link href="assets/css/style.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar">
        <a class="navbar-brand" href="index.php">Cinev Admin</a>
        <ul class="navbar-nav">
            <li><a class="nav-link active" href="index.php">Film Lokal</a></li>
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
            <h2>Daftar Film Lokal</h2>
            <a href="tambah.php" class="btn btn-primary">Tambah Film Baru</a>
        </div>
        
        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>No</th>
                        <th>Poster</th>
                        <th>Judul Film</th>
                        <th>Tipe</th>
                        <th>Tanggal Rilis</th>
                        <th>Video / Episode</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if($movies->num_rows > 0): $no = 1; while($row = $movies->fetch_assoc()): ?>
                    <tr>
                        <td><?= $no++ ?></td>
                        <td>
                            <img src="<?= htmlspecialchars($row['poster_path']) ?>" width="80" alt="Poster" class="img-thumbnail">
                        </td>
                        <td style="font-weight: 500;"><?= htmlspecialchars($row['title']) ?></td>
                        <td>
                            <?php if ($row['type'] == 'series'): ?>
                                <span class="badge badge-series">Series</span>
                            <?php else: ?>
                                <span class="badge badge-movie">Movie</span>
                            <?php endif; ?>
                        </td>
                        <td style="color: var(--text-muted);"><?= $row['release_date'] ?></td>
                        <td>
                            <?php if ($row['type'] == 'series'): ?>
                                <a href="episodes.php?movie_id=<?= $row['id'] ?>" class="btn btn-sm btn-primary">Kelola Episode</a>
                            <?php else: ?>
                                <a href="<?= htmlspecialchars($row['video_url']) ?>" target="_blank" class="btn btn-sm btn-outline">Lihat Video</a>
                            <?php endif; ?>
                        </td>
                        <td>
                            <a href="hapus.php?id=<?= $row['id'] ?>" class="btn btn-sm btn-danger" onclick="return confirm('Yakin ingin menghapus film ini?')">Hapus</a>
                        </td>
                    </tr>
                    <?php endwhile; else: ?>
                    <tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 3rem;">Belum ada film yang di-upload.</td></tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
