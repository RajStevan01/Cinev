<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $user_uid = $_POST['user_uid'] ?? '';
    $id_film = $_POST['id_film'] ?? '';

    if (empty($user_uid) || empty($id_film)) {
        echo json_encode(["status" => "error", "message" => "Data tidak lengkap"]);
        exit;
    }

    $id_film = (int)$id_film;

    // Cek apakah sudah like
    $check_sql = "SELECT id FROM tb_likes WHERE user_uid = ? AND id_film = ?";
    $stmt = $conn->prepare($check_sql);
    $stmt->bind_param("si", $user_uid, $id_film);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // Jika sudah like, hapus like (unlike)
        $del_sql = "DELETE FROM tb_likes WHERE user_uid = ? AND id_film = ?";
        $stmt_del = $conn->prepare($del_sql);
        $stmt_del->bind_param("si", $user_uid, $id_film);
        $stmt_del->execute();
        echo json_encode(["status" => "success", "message" => "Like dihapus", "is_liked" => false]);
    } else {
        // Jika belum, tambahkan like
        $ins_sql = "INSERT INTO tb_likes (user_uid, id_film) VALUES (?, ?)";
        $stmt_ins = $conn->prepare($ins_sql);
        $stmt_ins->bind_param("si", $user_uid, $id_film);
        $stmt_ins->execute();
        echo json_encode(["status" => "success", "message" => "Like ditambahkan", "is_liked" => true]);
    }
}
$conn->close();
?>
