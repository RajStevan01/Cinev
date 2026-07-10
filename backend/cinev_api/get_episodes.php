<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Content-Type: application/json; charset=UTF-8");

require 'koneksi.php';

if (!isset($_GET['movie_id'])) {
    echo json_encode(["status" => "error", "message" => "movie_id tidak diberikan"]);
    exit;
}

$movie_id = (int)$_GET['movie_id'];

$sql = "SELECT id, movie_id, episode_number, title, video_url, created_at 
        FROM tb_local_episodes 
        WHERE movie_id = $movie_id 
        ORDER BY episode_number ASC";

$result = $conn->query($sql);

$episodes = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $host = $_SERVER['HTTP_HOST'];
        $video_url = preg_replace('/http:\/\/[^\/]+\//', 'http://' . $host . '/', $row["video_url"]);

        $ep = array(
            "id" => (int)$row["id"],
            "movie_id" => (int)$row["movie_id"],
            "episode_number" => (int)$row["episode_number"],
            "title" => $row["title"],
            "video_url" => $video_url,
            "created_at" => $row["created_at"]
        );
        array_push($episodes, $ep);
    }
}

echo json_encode(array("status" => "success", "episodes" => $episodes));
$conn->close();
?>
