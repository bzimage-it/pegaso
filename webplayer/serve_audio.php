<?php
/**
 * Audio file server with HTTP Range Request support
 * This allows proper seeking in large audio files
 */

// Debug mode - remove this in production
$debug = isset($_GET['debug']);

if ($debug) {
    // For debug, we'll output HTML instead of audio
    echo "<h1>Debug serve_audio.php</h1>";
    echo "<p>File parameter: " . htmlspecialchars($_GET['file'] ?? 'NOT SET') . "</p>";
}

// Get the requested file path from query parameter
$fileParam = $_GET['file'] ?? '';

if ($debug) {
    echo "<p>File param after processing: " . htmlspecialchars($fileParam) . "</p>";
}

// Security: prevent directory traversal
if (strpos($fileParam, '..') !== false || empty($fileParam)) {
    if ($debug) {
        echo "<p style='color: red;'>Access denied - invalid file parameter</p>";
        exit;
    }
    http_response_code(403);
    die('Access denied');
}

// Construct the full file path
$filePath = __DIR__ . '/media/' . $fileParam;

if ($debug) {
    echo "<p>Full file path: " . htmlspecialchars($filePath) . "</p>";
    echo "<p>File exists: " . (file_exists($filePath) ? 'YES' : 'NO') . "</p>";
    echo "<p>Is file: " . (is_file($filePath) ? 'YES' : 'NO') . "</p>";
}

// Check if file exists and is a valid audio file
if (!file_exists($filePath) || !is_file($filePath)) {
    if ($debug) {
        echo "<p style='color: red;'>File not found: " . htmlspecialchars($filePath) . "</p>";
        exit;
    }
    http_response_code(404);
    die('File not found');
}

// Check if it's a valid audio file extension
$audioExtensions = ['aac', 'm4a', 'mp3', 'wav', 'ogg', 'flac', 'mp4'];
$extension = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
if (!in_array($extension, $audioExtensions)) {
    if ($debug) {
        echo "<p style='color: red;'>Invalid file type: " . htmlspecialchars($extension) . "</p>";
        exit;
    }
    http_response_code(403);
    die('Invalid file type');
}

// Get file info
$fileSize = filesize($filePath);
$fileName = basename($filePath);

// Determine MIME type
$mimeTypes = [
    'aac' => 'audio/aac',
    'm4a' => 'audio/mp4',
    'mp3' => 'audio/mpeg',
    'mp4' => 'audio/mp4',
    'wav' => 'audio/wav',
    'ogg' => 'audio/ogg',
    'flac' => 'audio/flac'
];

$ext = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
$mimeType = isset($mimeTypes[$ext]) ? $mimeTypes[$ext] : 'application/octet-stream';

if ($debug) {
    echo "<p>File extension: " . htmlspecialchars($ext) . "</p>";
    echo "<p>MIME type: " . htmlspecialchars($mimeType) . "</p>";
    echo "<p>File size: " . number_format($fileSize) . " bytes</p>";
    echo "<p><strong>Debug complete - file found and valid!</strong></p>";
    echo "<p>To test audio playback, remove &debug=1 from the URL</p>";
    exit;
}

// Handle range requests
$start = 0;
$end = $fileSize - 1;
$length = $fileSize;

if (isset($_SERVER['HTTP_RANGE'])) {
    // Parse Range header
    if (preg_match('/bytes=(\d+)-(\d*)/', $_SERVER['HTTP_RANGE'], $matches)) {
        $start = intval($matches[1]);
        if (!empty($matches[2])) {
            $end = intval($matches[2]);
        }
        
        // Validate range
        if ($start > $end || $start >= $fileSize || $end >= $fileSize) {
            header('HTTP/1.1 416 Requested Range Not Satisfiable');
            header("Content-Range: bytes */$fileSize");
            exit;
        }
        
        $length = $end - $start + 1;
        
        // Send 206 Partial Content
        http_response_code(206);
        header("Content-Range: bytes $start-$end/$fileSize");
    }
} else {
    // Normal request
    http_response_code(200);
}

// Send headers
header("Content-Type: $mimeType");
header("Content-Length: $length");
header("Accept-Ranges: bytes");
header("Cache-Control: public, max-age=3600");

// For downloads (optional)
// header("Content-Disposition: inline; filename=\"$fileName\"");

// Open file and seek to start position
$fp = fopen($filePath, 'rb');
if ($fp === false) {
    http_response_code(500);
    die('Cannot open file');
}

fseek($fp, $start);

// Stream the file in chunks
$buffer = 8192; // 8KB chunks
$bytesRemaining = $length;

while ($bytesRemaining > 0 && !feof($fp)) {
    $chunkSize = min($buffer, $bytesRemaining);
    $data = fread($fp, $chunkSize);
    
    if ($data === false) {
        break;
    }
    
    echo $data;
    flush();
    
    $bytesRemaining -= strlen($data);
}

fclose($fp);
exit;
?>

