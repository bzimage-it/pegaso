<?php
/**
 * Audio file server with HTTP Range Request support
 * This allows proper seeking in large audio files
 */

// Get the requested file path
$requestUri = $_SERVER['REQUEST_URI'];

// Extract file path from URI (remove query string if present)
$requestUri = strtok($requestUri, '?');

// Security: prevent directory traversal
if (strpos($requestUri, '..') !== false) {
    http_response_code(403);
    die('Access denied');
}

// Check if this is a request for a media file
if (strpos($requestUri, '/media/') === 0) {
    // Remove leading slash and get file path
    $filePath = __DIR__ . $requestUri;
    
    // Check if file exists
    if (!file_exists($filePath) || !is_file($filePath)) {
        http_response_code(404);
        die('File not found');
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
}

// If not a media file request, return false to let PHP handle it normally
return false;
?>

