<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

$banners = $conn->query("SELECT * FROM tb_banners ORDER BY created_at DESC");
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manajemen Banner - Cinev</title>
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
            <h2>Daftar Banner Iklan</h2>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#modalTambahBanner">Tambah Banner Baru</button>
        </div>
        
        <?php if(isset($_SESSION['pesan'])): ?>
            <div class="alert alert-info">
                <?= $_SESSION['pesan']; unset($_SESSION['pesan']); ?>
            </div>
        <?php endif; ?>

        <div class="row">
            <?php if($banners->num_rows > 0): while($row = $banners->fetch_assoc()): ?>
            <div class="col-md-4 mb-4">
                <div class="card h-100">
                    <img src="<?= $row['path_gambar'] ?>" class="card-img-top" alt="Banner" style="height: 150px; object-fit: cover;">
                    <div class="card-body">
                        <h5 class="card-title"><?= htmlspecialchars($row['judul']) ?></h5>
                        <p class="card-text mb-1"><strong>Posisi:</strong> <span class="badge bg-<?= $row['posisi'] == 'home' ? 'success' : 'info' ?>"><?= strtoupper($row['posisi']) ?></span></p>
                        <?php if($row['link_url']): ?>
                            <a href="<?= htmlspecialchars($row['link_url']) ?>" target="_blank" class="text-truncate d-block" style="max-width: 100%;"><?= htmlspecialchars($row['link_url']) ?></a>
                        <?php else: ?>
                            <span class="text-muted">Tidak ada link</span>
                        <?php endif; ?>
                    </div>
                    <div class="card-footer bg-white border-top-0">
                        <a href="hapus_banner.php?id=<?= $row['id'] ?>" class="btn btn-danger w-100" onclick="return confirm('Hapus banner ini?')">Hapus</a>
                    </div>
                </div>
            </div>
            <?php endwhile; else: ?>
            <div class="col-12"><p class="text-center text-muted">Belum ada banner iklan.</p></div>
            <?php endif; ?>
        </div>
    </div>

    <!-- Modal Tambah Banner -->
    <div class="modal fade" id="modalTambahBanner" tabindex="-1">
      <div class="modal-dialog">
        <form action="tambah_banner.php" method="POST" enctype="multipart/form-data" class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Upload Banner Baru</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <div class="mb-3">
                <label>Judul Banner</label>
                <input type="text" name="judul" class="form-control" placeholder="Contoh: Iklan Kopi" required>
            </div>
            <div class="mb-3">
                <label>Posisi Tampil</label>
                <select name="posisi" class="form-select" required>
                    <option value="home">Halaman Utama (Carousel Bergeser)</option>
                    <option value="player">Halaman Pemutar Video (Bawah Video)</option>
                </select>
            </div>
            <div class="mb-3">
                <label>Pilih File Gambar (Disarankan orientasi lanskap)</label>
                <input type="file" name="file_banner" class="form-control" accept="image/*" required>
            </div>
            <div class="mb-3">
                <label>Tautan Iklan / Link (Opsional)</label>
                <input type="url" name="link_url" class="form-control" placeholder="https://contoh.com">
                <small class="text-muted">Website akan terbuka jika banner ditekan.</small>
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
