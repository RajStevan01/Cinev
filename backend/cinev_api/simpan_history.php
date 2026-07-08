<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'koneksi.php';

if (!$conn) {
    echo json_encode(["status" => "error", "message" => "Database connection failed"]);
    exit();
}

$user_uid = $_POST['user_uid'] ?? '';
$id_film = $_POST['id_film'] ?? '';
$progress_seconds = $_POST['progress_seconds'] ?? 0;
$total_seconds = $_POST['total_seconds'] ?? 0;

if (empty($user_uid) || empty($id_film)) {
    echo json_encode(["status" => "error", "message" => "user_uid and id_film required"]);
    exit();
}

date_default_timezone_set('Asia/Jakarta');
$waktu_nonton = date('Y-m-d H:i:s');

$sql_check = "SELECT id FROM tb_history WHERE user_uid = '$user_uid' AND id_film = '$id_film'";
$result_check = $conn->query($sql_check);

if ($result_check->num_rows > 0) {
    $sql_update = "UPDATE tb_history SET progress_seconds = '$progress_seconds', total_seconds = '$total_seconds', waktu_nonton = '$waktu_nonton' WHERE user_uid = '$user_uid' AND id_film = '$id_film'";
    if ($conn->query($sql_update) === TRUE) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => $conn->error]);
    }
} else {
    $sql_insert = "INSERT INTO tb_history (user_uid, id_film, progress_seconds, total_seconds, waktu_nonton) VALUES ('$user_uid', '$id_film', '$progress_seconds', '$total_seconds', '$waktu_nonton')";
    if ($conn->query($sql_insert) === TRUE) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => $conn->error]);
    }
}
$conn->close();
?>
