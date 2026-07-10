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
    <link href="assets/css/style.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar">
        <a class="navbar-brand" href="index.php">Cinev Admin</a>
        <ul class="navbar-nav">
            <li><a class="nav-link" href="index.php">Film Lokal</a></li>
            <li><a class="nav-link active" href="avatars.php">Manajemen Avatar</a></li>
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
            <h2>Daftar Avatar</h2>
            <button class="btn btn-primary" onclick="openModal('modalTambahAvatar')">Tambah Avatar</button>
        </div>
        
        <?php if(isset($_SESSION['pesan'])): ?>
            <div class="alert alert-danger">
                <?= $_SESSION['pesan']; unset($_SESSION['pesan']); ?>
            </div>
        <?php endif; ?>

        <div class="row">
            <?php if($avatars->num_rows > 0): while($row = $avatars->fetch_assoc()): ?>
            <div class="col-md-2">
                <div class="card">
                    <?php $localPath = "../cinev_api/avatars/" . basename($row['path_gambar']); ?>
                    <img src="<?= htmlspecialchars($localPath) ?>" class="card-img-top p-2" alt="Avatar" style="height: 120px; object-fit: contain;">
                    <div class="card-body">
                        <small style="display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; margin-bottom: 0.5rem;"><?= htmlspecialchars($row['nama_avatar']) ?></small>
                        <a href="hapus_avatar.php?id=<?= $row['id'] ?>" class="btn btn-sm btn-danger" style="width: 100%;" onclick="return confirm('Hapus avatar ini?')">Hapus</a>
                    </div>
                </div>
            </div>
            <?php endwhile; else: ?>
            <div class="col-12"><p style="color: var(--text-muted);">Belum ada avatar yang diunggah.</p></div>
            <?php endif; ?>
        </div>
    </div>

    <!-- Modal Tambah Avatar -->
    <div id="modalTambahAvatar" class="modal">
        <form action="tambah_avatar.php" method="POST" enctype="multipart/form-data" class="modal-content">
            <div class="modal-header">
                <h3 style="margin: 0; font-size: 1.25rem;">Upload Avatar Baru</h3>
                <button type="button" class="btn-close" onclick="closeModal('modalTambahAvatar')">×</button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">Nama Avatar (Opsional)</label>
                    <input type="text" name="nama_avatar" class="form-control" placeholder="Contoh: Cowok Kacamata">
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label">Pilih File (JPG/PNG)</label>
                    <input type="file" name="file_avatar" class="form-control" accept="image/png, image/jpeg" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline" onclick="closeModal('modalTambahAvatar')">Batal</button>
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
        // Menutup modal jika klik di luar konten
        window.onclick = function(event) {
            if (event.target.classList.contains('modal')) {
                event.target.classList.remove('show');
            }
        }
    </script>
</body>
</html>
