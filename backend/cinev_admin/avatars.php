<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

$avatars = $conn->query("SELECT * FROM tb_avatars ORDER BY created_at DESC");
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manajemen Avatar - Cinev</title>
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
            <h2>Daftar Avatar</h2>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#modalTambahAvatar">Tambah Avatar</button>
        </div>
        
        <?php if(isset($_SESSION['pesan'])): ?>
            <div class="alert alert-info">
                <?= $_SESSION['pesan']; unset($_SESSION['pesan']); ?>
            </div>
        <?php endif; ?>

        <div class="row">
            <?php if($avatars->num_rows > 0): while($row = $avatars->fetch_assoc()): ?>
            <div class="col-md-2 mb-4 text-center">
                <div class="card">
                    <img src="<?= $row['path_gambar'] ?>" class="card-img-top p-2" alt="Avatar" style="height: 120px; object-fit: contain;">
                    <div class="card-body p-2">
                        <small class="d-block text-truncate"><?= htmlspecialchars($row['nama_avatar']) ?></small>
                        <a href="hapus_avatar.php?id=<?= $row['id'] ?>" class="btn btn-sm btn-danger mt-2 w-100" onclick="return confirm('Hapus avatar ini?')">Hapus</a>
                    </div>
                </div>
            </div>
            <?php endwhile; else: ?>
            <div class="col-12"><p class="text-center text-muted">Belum ada avatar yang diunggah.</p></div>
            <?php endif; ?>
        </div>
    </div>

    <!-- Modal Tambah Avatar -->
    <div class="modal fade" id="modalTambahAvatar" tabindex="-1">
      <div class="modal-dialog">
        <form action="tambah_avatar.php" method="POST" enctype="multipart/form-data" class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Upload Avatar Baru</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <div class="mb-3">
                <label>Nama Avatar (Opsional)</label>
                <input type="text" name="nama_avatar" class="form-control" placeholder="Contoh: Cowok Kacamata">
            </div>
            <div class="mb-3">
                <label>Pilih File (JPG/PNG)</label>
                <input type="file" name="file_avatar" class="form-control" accept="image/png, image/jpeg" required>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
            <button type="submit" class="btn btn-primary">Upload</button>
          </div>
        </form>
      </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
