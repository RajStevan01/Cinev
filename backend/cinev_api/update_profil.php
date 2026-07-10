<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'koneksi.php';

// Mendukung pembacaan raw JSON atau form-data
$input = file_get_contents("php://input");
$data = json_decode($input, true);

if (!$data) {
    $data = $_POST;
}

$user_uid = $data['user_uid'] ?? '';
$photo_url = $data['photo_url'] ?? '';
$username = $data['username'] ?? ''; // Opsional jika ingin update nama juga

if (empty($user_uid)) {
    echo json_encode(["status" => "error", "message" => "User UID tidak boleh kosong"]);
    exit;
}

// Susun kueri UPDATE secara dinamis
$updates = [];
$params = [];
$types = "";

if ($photo_url !== '') {
    $updates[] = "photo_url = ?";
    $params[] = $photo_url;
    $types .= "s";
}

if ($username !== '') {
    $updates[] = "username = ?";
    $params[] = $username;
    $types .= "s";
}

if (empty($updates)) {
    echo json_encode(["status" => "success", "message" => "Tidak ada data yang diubah"]);
    exit;
}

// Tambahkan user_uid ke parameter paling akhir untuk klausa WHERE
$params[] = $user_uid;
$types .= "s";

$sql = "UPDATE users SET " . implode(", ", $updates) . " WHERE uid = ?";
$stmt = $conn->prepare($sql);

// Bind parameter secara dinamis
$stmt->bind_param($types, ...$params);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Profil berhasil diperbarui"]);
} else {
    echo json_encode(["status" => "error", "message" => "Gagal memperbarui profil: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
