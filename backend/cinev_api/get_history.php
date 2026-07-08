<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'koneksi.php';

if (!$conn) {
    echo json_encode(["status" => "error", "message" => "Database connection failed"]);
    exit();
}

$user_uid = $_GET['user_uid'] ?? '';

if (empty($user_uid)) {
    echo json_encode(["status" => "error", "message" => "user_uid required"]);
    exit();
}

$sql = "SELECT h.progress_seconds, h.total_seconds, h.waktu_nonton, m.id, m.title, m.overview, m.release_date, m.poster_path, m.backdrop_path, m.vote_average, m.video_url
        FROM tb_history h 
        JOIN tb_local_movies m ON h.id_film = m.id 
        WHERE h.user_uid = '$user_uid' 
        ORDER BY h.waktu_nonton DESC";

$result = $conn->query($sql);
$history = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $host = $_SERVER['HTTP_HOST'];
        $row["id"] = (int)$row["id"];
        $row["vote_average"] = (double)$row["vote_average"];
        $row["poster_path"] = preg_replace('/http:\/\/[^\/]+\//', 'http://' . $host . '/', $row["poster_path"]);
        $row["backdrop_path"] = preg_replace('/http:\/\/[^\/]+\//', 'http://' . $host . '/', $row["backdrop_path"]);
        $row["video_url"] = preg_replace('/http:\/\/[^\/]+\//', 'http://' . $host . '/', $row["video_url"]);
        $history[] = $row;
    }
}

echo json_encode($history);
$conn->close();
?>
