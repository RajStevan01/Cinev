<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $user_uid = $_POST['user_uid'] ?? '';
    $id_film = $_POST['id_film'] ?? '';
    $rating = $_POST['rating'] ?? 0;
    $komentar = $_POST['komentar'] ?? '';

    if (empty($user_uid) || empty($id_film) || empty($rating)) {
        echo json_encode(["status" => "error", "message" => "Data tidak lengkap"]);
        exit;
    }

    $rating = (int)$rating;
    $id_film = (int)$id_film;

    // Cek apakah user sudah mereview film ini sebelumnya
    $check_sql = "SELECT id FROM tb_reviews WHERE user_uid = ? AND id_film = ?";
    $stmt_check = $conn->prepare($check_sql);
    $stmt_check->bind_param("si", $user_uid, $id_film);
    $stmt_check->execute();
    $result = $stmt_check->get_result();

    if ($result->num_rows > 0) {
        // Update review yang ada
        $update_sql = "UPDATE tb_reviews SET rating = ?, komentar = ?, waktu_dibuat = CURRENT_TIMESTAMP WHERE user_uid = ? AND id_film = ?";
        $stmt_update = $conn->prepare($update_sql);
        $stmt_update->bind_param("issi", $rating, $komentar, $user_uid, $id_film);
        if ($stmt_update->execute()) {
            echo json_encode(["status" => "success", "message" => "Ulasan berhasil diperbarui"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Gagal memperbarui ulasan"]);
        }
    } else {
        // Insert review baru
        $insert_sql = "INSERT INTO tb_reviews (user_uid, id_film, rating, komentar) VALUES (?, ?, ?, ?)";
        $stmt_insert = $conn->prepare($insert_sql);
        $stmt_insert->bind_param("siis", $user_uid, $id_film, $rating, $komentar);
        if ($stmt_insert->execute()) {
            echo json_encode(["status" => "success", "message" => "Ulasan berhasil disimpan"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Gagal menyimpan ulasan"]);
        }
    }
}
$conn->close();
?>
