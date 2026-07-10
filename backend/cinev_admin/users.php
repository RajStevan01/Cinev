<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header("Location: login.php");
    exit;
}
require 'koneksi.php';

$users = $conn->query("SELECT * FROM users ORDER BY username ASC");
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manajemen User - Cinev Admin</title>
    <link href="assets/css/style.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar">
        <a class="navbar-brand" href="index.php">Cinev Admin</a>
        <ul class="navbar-nav">
            <li><a class="nav-link" href="index.php">Film Lokal</a></li>
            <li><a class="nav-link" href="avatars.php">Manajemen Avatar</a></li>
            <li><a class="nav-link" href="banners.php">Manajemen Banner</a></li>
            <li><a class="nav-link active" href="users.php">Manajemen User</a></li>
        </ul>
        <div class="nav-user">
            <span>Halo, <?= $_SESSION['admin'] ?></span>
            <a href="logout.php" class="btn btn-outline btn-sm">Logout</a>
        </div>
    </nav>

    <div class="container">
        <div class="header-actions">
            <h2>Daftar User Terdaftar</h2>
        </div>
        
        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>No</th>
                        <th>Foto Profil</th>
                        <th>Username</th>
                        <th>Email</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if($users && $users->num_rows > 0): $no = 1; while($row = $users->fetch_assoc()): ?>
                    <tr>
                        <td><?= $no++ ?></td>
                        <td>
                            <?php if(!empty($row['photo_url'])): ?>
                                <?php $localPath = "../cinev_api/avatars/" . basename($row['photo_url']); ?>
                                <img src="<?= htmlspecialchars($localPath) ?>" width="50" height="50" style="border-radius: 50%; object-fit: cover; border: 2px solid var(--primary-color);" alt="Foto">
                            <?php else: ?>
                                <div style="width:50px; height:50px; border-radius:50%; background: rgba(0,245,255,0.1); border: 2px solid var(--panel-border); display:flex; align-items:center; justify-content:center;">
                                    <span style="color:var(--primary-color); font-size:20px;">👤</span>
                                </div>
                            <?php endif; ?>
                        </td>
                        <td style="font-weight: 500; font-size: 1.1rem; color: var(--text-main);"><?= htmlspecialchars($row['username']) ?></td>
                        <td style="color: var(--text-muted);"><?= htmlspecialchars($row['email']) ?></td>
                    </tr>
                    <?php endwhile; else: ?>
                    <tr><td colspan="4" style="text-align: center; color: var(--text-muted); padding: 3rem;">Belum ada user yang mendaftar.</td></tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
