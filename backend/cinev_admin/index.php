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
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container">
            <a class="navbar-brand" href="index.php">Cinev Admin</a>
            <div class="collapse navbar-collapse">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item"><a class="nav-link" href="index.php">Film Lokal</a></li>
                    <li class="nav-item"><a class="nav-link" href="avatars.php">Manajemen Avatar</a></li>
                    <li class="nav-item"><a class="nav-link" href="banners.php">Manajemen Banner</a></li>
                </ul>
            </div>
            <div class="d-flex">
                <span class="navbar-text me-3">Halo, <?= $_SESSION['admin'] ?></span>
                <a href="logout.php" class="btn btn-outline-light btn-sm">Logout</a>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h2>Daftar Film Lokal</h2>
            <a href="tambah.php" class="btn btn-primary">Tambah Film Baru</a>
        </div>
        
        <table class="table table-bordered table-striped">
            <thead class="table-dark">
                <tr>
                    <th>No</th>
                    <th>Poster</th>
                    <th>Judul Film</th>
                    <th>Tanggal Rilis</th>
                    <th>Video</th>
                    <th>Aksi</th>
                </tr>
            </thead>
            <tbody>
                <?php if($movies->num_rows > 0): $no = 1; while($row = $movies->fetch_assoc()): ?>
                <tr>
                    <td><?= $no++ ?></td>
                    <td>
                        <img src="<?= $row['poster_path'] ?>" width="80" alt="Poster">
                    </td>
                    <td><?= htmlspecialchars($row['title']) ?></td>
                    <td><?= $row['release_date'] ?></td>
                    <td>
                        <a href="<?= $row['video_url'] ?>" target="_blank" class="btn btn-sm btn-info text-white">Lihat Video</a>
                    </td>
                    <td>
                        <a href="hapus.php?id=<?= $row['id'] ?>" class="btn btn-sm btn-danger" onclick="return confirm('Yakin ingin menghapus film ini?')">Hapus</a>
                    </td>
                </tr>
                <?php endwhile; else: ?>
                <tr><td colspan="6" class="text-center">Belum ada film yang di-upload.</td></tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</body>
</html>
