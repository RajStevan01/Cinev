<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Content-Type: application/json; charset=UTF-8");

require 'koneksi.php';

$sql = "SELECT id, title, overview, poster_path, backdrop_path, video_url, release_date, vote_average, type, created_at 
        FROM tb_local_movies 
        ORDER BY created_at DESC";

$result = $conn->query($sql);

$movies = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // Ambil host/IP yang sedang mengakses API ini (misal 10.0.2.2 atau 192.168.x.x)
        $host = $_SERVER['HTTP_HOST'];
        
        // Replace IP lama di database menjadi IP yang baru/sekarang agar gambar tidak error
        $poster_path = preg_replace('/http:\/\/[^\/]+\//', 'http://' . $host . '/', $row["poster_path"]);
        $backdrop_path = preg_replace('/http:\/\/[^\/]+\//', 'http://' . $host . '/', $row["backdrop_path"]);
        $video_url = preg_replace('/http:\/\/[^\/]+\//', 'http://' . $host . '/', $row["video_url"]);

        $movie = array(
            "id" => (int)$row["id"],
            "title" => $row["title"],
            "overview" => isset($row["overview"]) ? $row["overview"] : "",
            "poster_path" => $poster_path,
            "backdrop_path" => $backdrop_path,
            "video_url" => $video_url,
            "release_date" => isset($row["release_date"]) ? $row["release_date"] : date("Y-m-d"),
            "vote_average" => isset($row["vote_average"]) ? (double)$row["vote_average"] : 0.0,
            "type" => isset($row["type"]) ? $row["type"] : "movie",
            "is_local" => true 
        );
        array_push($movies, $movie);
    }
}

echo json_encode(array("results" => $movies));
$conn->close();
?>
