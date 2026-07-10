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
    <link href="assets/css/style.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar">
        <a class="navbar-brand" href="index.php">Cinev Admin</a>
        <ul class="navbar-nav">
            <li><a class="nav-link" href="index.php">Film Lokal</a></li>
            <li><a class="nav-link" href="avatars.php">Manajemen Avatar</a></li>
            <li><a class="nav-link active" href="banners.php">Manajemen Banner</a></li>
            <li><a class="nav-link" href="users.php">Manajemen User</a></li>
        </ul>
        <div class="nav-user">
            <span>Halo, <?= $_SESSION['admin'] ?></span>
            <a href="logout.php" class="btn btn-outline btn-sm">Logout</a>
        </div>
    </nav>

    <div class="container">
        <div class="header-actions">
            <h2>Daftar Banner Iklan</h2>
            <button class="btn btn-primary" onclick="openModal('modalTambahBanner')">Tambah Banner Baru</button>
        </div>
        
        <?php if(isset($_SESSION['pesan'])): ?>
            <div class="alert alert-danger">
                <?= $_SESSION['pesan']; unset($_SESSION['pesan']); ?>
            </div>
        <?php endif; ?>

        <div class="row">
            <?php if($banners->num_rows > 0): while($row = $banners->fetch_assoc()): ?>
            <div class="col-md-2" style="flex: 0 0 calc(33.333% - 1.5rem); max-width: calc(33.333% - 1.5rem);">
                <div class="card" style="display: flex; flex-direction: column; height: 100%;">
                    <?php $localPath = "../cinev_api/banners/" . basename($row['path_gambar']); ?>
                    <img src="<?= htmlspecialchars($localPath) ?>" class="card-img-top p-2" alt="Banner" style="height: 150px; object-fit: contain; border-radius: 8px;">
                    <div class="card-body" style="flex-grow: 1; display: flex; flex-direction: column; justify-content: space-between;">
                        <div>
                            <h3 style="font-size: 1.1rem; margin-bottom: 0.5rem;"><?= htmlspecialchars($row['judul']) ?></h3>
                            <p style="color: var(--text-muted); font-size: 0.85rem; margin-bottom: 0.5rem;">
                                <strong>Posisi:</strong> <span class="badge <?= $row['posisi'] == 'home' ? 'badge-series' : 'badge-movie' ?>"><?= strtoupper($row['posisi']) ?></span>
                            </p>
                            <?php if($row['link_url']): ?>
                                <a href="<?= htmlspecialchars($row['link_url']) ?>" target="_blank" style="font-size: 0.85rem; display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; margin-bottom: 1rem; color: var(--primary-color);"><?= htmlspecialchars($row['link_url']) ?></a>
                            <?php else: ?>
                                <span style="font-size: 0.85rem; color: var(--text-muted); display: block; margin-bottom: 1rem;">Tidak ada link</span>
                            <?php endif; ?>
                        </div>
                        <a href="hapus_banner.php?id=<?= $row['id'] ?>" class="btn btn-danger" style="width: 100%;" onclick="return confirm('Hapus banner ini?')">Hapus</a>
                    </div>
                </div>
            </div>
            <?php endwhile; else: ?>
            <div class="col-12"><p style="color: var(--text-muted);">Belum ada banner iklan.</p></div>
            <?php endif; ?>
        </div>
    </div>

    <!-- Modal Tambah Banner -->
    <div id="modalTambahBanner" class="modal">
        <form action="tambah_banner.php" method="POST" enctype="multipart/form-data" class="modal-content">
            <div class="modal-header">
                <h3 style="margin: 0; font-size: 1.25rem;">Upload Banner Baru</h3>
                <button type="button" class="btn-close" onclick="closeModal('modalTambahBanner')">×</button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">Judul Banner</label>
                    <input type="text" name="judul" class="form-control" placeholder="Contoh: Iklan Kopi" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Posisi Tampil</label>
                    <select name="posisi" class="form-control" required>
                        <option value="home">Halaman Utama (Carousel Bergeser)</option>
                        <option value="player">Halaman Pemutar Video (Bawah Video)</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Pilih File Gambar (Disarankan orientasi lanskap)</label>
                    <input type="file" name="file_banner" class="form-control" accept="image/*" required>
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label">Tautan Iklan / Link (Opsional)</label>
                    <input type="url" name="link_url" class="form-control" placeholder="https://contoh.com">
                    <small style="color: var(--text-muted); font-size: 0.8rem; display: block; margin-top: 0.5rem;">Website akan terbuka jika banner ditekan.</small>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline" onclick="closeModal('modalTambahBanner')">Batal</button>
                <button type="submit" class="btn btn-primary">Upload</button>
            </div>
        </form>
    </div>

    <script>
        function openModal(id) {
            document.getElementById(id).classList.add('show');
        }
        function closeModal(id) {
            document.getElementById(id).classList.remove('show');
        }
        window.onclick = function(event) {
            if (event.target.classList.contains('modal')) {
                event.target.classList.remove('show');
            }
        }
    </script>
</body>
</html>
